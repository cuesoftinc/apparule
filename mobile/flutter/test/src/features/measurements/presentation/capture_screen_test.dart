import 'package:apparule/src/core/ui/capture_overlay.dart';
import 'package:apparule/src/core/ui/capture_results.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/camera_service_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/capture_screen.dart';
import 'package:apparule/src/features/measurements/presentation/capture_view_model.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_screen.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C6 two-pose capture over the fake camera (mobile-implementation.md
/// §10, M-10): front "Pose 1 of 2" → side "Pose 2 of 2" → processing →
/// results, the height step when not on file, per-pose first-failure QC
/// with retry-never-advances semantics, the permission-denied fallback,
/// and save-to-vault (C7).
///
/// Booted through the real router (the flow navigates); bounded pumps
/// where the viewfinder/constellation animate (MI-12 never settles).
void main() {
  Future<void> bootToCapture(
    WidgetTester tester, {
    CameraServiceFake? camera,
    MeasurementRepository? measurementRepository,
  }) async {
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      cameraService: camera,
      measurementRepository: measurementRepository,
      preferences: <String, Object>{'capture_guide_seen': true},
    );
    routerOf(tester).go(const CaptureRoute().location);
    // The flow opens on the viewfinder (MI-12 pulses — never settle):
    // pump past the camera-init microtask AND the route transition, in
    // slices that stay short of the auto-capture arming delay.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// One pose's auto-capture (QA-convergence ruling: no shutter): the
  /// searching beat arms the 3-2-1 → capture fires on completion.
  Future<void> shootPose(WidgetTester tester) async {
    await tester.pump(kCaptureAlignDelay);
    await tester.pump();
    expect(find.bySemanticsLabel('Capturing in 3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Capturing in 2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Capturing in 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  /// Front + side, then the fake pipeline's simulated latency.
  Future<void> shootBothPosesThroughProcessing(WidgetTester tester) async {
    expect(find.text('Pose 1 of 2'), findsOneWidget);
    await shootPose(tester);
    expect(find.text('Pose 2 of 2'), findsOneWidget);
    await shootPose(tester);
    // The side capture's async take-photo → submit chain, then the
    // fake pipeline's simulated latency (the processing constellation
    // state is pinned by the screen goldens; the pump slices here can
    // land on either side of the 600ms resolve).
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
  }

  group('two-pose sequence (M-10: front → side → processing)', () {
    testWidgets('opens on Pose 1 of 2 with the front silhouette and NO '
        'height step (height on file)', (tester) async {
      await bootToCapture(tester);

      expect(find.byType(CaptureOverlay), findsOneWidget);
      expect(find.text('Pose 1 of 2'), findsOneWidget);
      expect(find.text('Stand inside the outline'), findsOneWidget);
      expect(find.text('Your height'), findsNothing);
    });

    testWidgets('advances to Pose 2 of 2 with the side silhouette hint '
        'after the front capture', (tester) async {
      await bootToCapture(tester);

      await shootPose(tester);

      expect(find.text('Pose 2 of 2'), findsOneWidget);
      expect(
        find.text('Turn your right side to the camera'),
        findsOneWidget,
      );
      expect(find.text('Stand inside the outline'), findsNothing);
    });

    testWidgets('countdown → countdown → processing → results with §4 '
        'confidences, save lands in the vault', (tester) async {
      await bootToCapture(tester);
      await shootBothPosesThroughProcessing(tester);

      // Results: scaled values (168 cm over the sample metrics — 42.6/
      // 35.5 cm canonical, inches display by default, A-9) with the
      // low-confidence chip on the 0.62 hip (capture-qc.md §4).
      expect(find.byType(CaptureResults), findsOneWidget);
      expect(find.byType(MeasurementCard), findsNWidgets(2));
      expect(find.text('16.8 in'), findsOneWidget);
      expect(find.text('14.0 in'), findsOneWidget);
      expect(find.text('1 low confidence'), findsOneWidget);
      expect(find.text('Low confidence · 0.62'), findsOneWidget);

      await tester.tap(find.text('Save to vault'));
      await tester.pumpAndSettle();

      // C7 lists the saved session on arrival.
      expect(find.byType(VaultScreen), findsOneWidget);
      expect(find.text('Measured today'), findsOneWidget);
      expect(find.text('16.8 in'), findsOneWidget);
    });

    testWidgets('retake from results discards and restarts at Pose 1', (
      tester,
    ) async {
      await bootToCapture(tester);
      await shootBothPosesThroughProcessing(tester);

      await tester.tap(find.text('Retake'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CaptureOverlay), findsOneWidget);
      expect(find.byType(CaptureResults), findsNothing);
      expect(find.text('Pose 1 of 2'), findsOneWidget);

      // The auto-capture re-arms for the next shot.
      await tester.pump(kCaptureAlignDelay);
      await tester.pump();
      expect(find.bySemanticsLabel('Capturing in 3'), findsOneWidget);
    });
  });

  group('height step (flows/vault.md §1 — only when not on file)', () {
    testWidgets('interposes after Pose 2 for a user with no vault height, '
        'gates 100–230, then submits', (tester) async {
      await bootToCapture(
        tester,
        measurementRepository: MeasurementRepositoryFake(
          bundle: _NoVaultSeedBundle(),
          processingDelay: Duration.zero,
        ),
      );

      await shootPose(tester);
      await shootPose(tester);

      // The height step (canvas 530:4) — no stored height to prefill.
      expect(find.text('Your height'), findsOneWidget);

      // Entry is inches by default (A-9): 30 in = 76.2 cm, under the
      // canonical 100 cm floor — the gate copy renders the band in the
      // active display unit.
      await tester.enterText(find.bySemanticsLabel('Height value'), '30');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(
        find.text('Enter a height between 39–91 in.'),
        findsOneWidget,
      );

      // 67 in = 170.2 cm — inside the band; the submit proceeds.
      await tester.enterText(find.bySemanticsLabel('Height value'), '67');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CaptureResults), findsOneWidget);
    });

    testWidgets('the toggle defaults to inches (A-9) and converts the '
        'display both ways, storage stays cm', (tester) async {
      await bootToCapture(
        tester,
        measurementRepository: MeasurementRepositoryFake(
          bundle: _NoVaultSeedBundle(),
          processingDelay: Duration.zero,
        ),
      );
      await shootPose(tester);
      await shootPose(tester);

      // Inches active by default — the toggle offers the flip to cm.
      expect(find.bySemanticsLabel('Switch to cm'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Switch to cm'));
      await tester.pumpAndSettle();

      await tester.enterText(find.bySemanticsLabel('Height value'), '168');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Switch to in'));
      await tester.pumpAndSettle();

      // 168 cm = 66.1 in (one decimal, MI-13 display conversion) — the
      // committed value round-trips through canonical cm.
      expect(find.text('66.1'), findsOneWidget);
    });
  });

  group('auto-capture (QA-convergence ruling — canvas+docs, no shutter)', () {
    testWidgets('the viewfinder renders no shutter control and arms the '
        '3-2-1 by itself after the searching beat', (tester) async {
      await bootToCapture(tester);

      // No capture control anywhere on the controls layer.
      expect(find.bySemanticsLabel('Capture'), findsNothing);
      expect(find.text('Stand inside the outline'), findsOneWidget);
      expect(find.bySemanticsLabel('Capturing in 3'), findsNothing);

      // ...then the countdown starts on its own.
      await tester.pump(kCaptureAlignDelay);
      await tester.pump();
      expect(find.bySemanticsLabel('Capturing in 3'), findsOneWidget);
    });

    testWidgets('announces the countdowns, both captures, and the pose '
        'advance', (tester) async {
      final announcements = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            dynamic message,
          ) async {
            if (message case {
              'type': 'announce',
              'data': {'message': final String text},
            }) {
              announcements.add(text);
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );

      await bootToCapture(tester);
      await shootBothPosesThroughProcessing(tester);

      expect(
        announcements,
        containsAllInOrder(<String>[
          'Hold still — capturing in 3',
          'Photo captured',
          'Front photo captured — now turn your right side to the camera',
          'Hold still — capturing in 3',
          'Photo captured',
        ]),
      );
    });

    testWidgets('the manual-entry escape stays available on the live '
        'viewfinder', (tester) async {
      await bootToCapture(tester);

      await tester.tap(find.text('Enter manually instead'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualEntryScreen), findsOneWidget);
    });
  });

  group('per-pose QC failure surfacing (first-failure-only, per pose)', () {
    testWidgets('a failing FRONT frame renders exactly one QCHintChip and '
        'retake re-enters Pose 1', (tester) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(frontSampleId: 'qc_no_body'),
      );
      await shootPose(tester);
      await shootPose(tester);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(find.byType(QCHintChip), findsOneWidget);
      expect(
        find.text('Make sure your whole body is visible'),
        findsOneWidget,
      );
      // The QC-fail bar is title-less — a retry never advances the pose
      // counter (canvas 530:9017).
      expect(find.text('Pose 1 of 2'), findsNothing);
      expect(find.text('Pose 2 of 2'), findsNothing);

      await tester.tap(find.text('Retake'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(QCHintChip), findsNothing);
      expect(find.text('Pose 1 of 2'), findsOneWidget);
      expect(find.text('Stand inside the outline'), findsOneWidget);
    });

    testWidgets('a failing SIDE frame surfaces not_side_profile and retake '
        're-enters Pose 2 directly — pose 1 is never re-shot', (
      tester,
    ) async {
      final camera = CameraServiceFake(sideSampleId: 'qc_not_side_profile');
      await bootToCapture(tester, camera: camera);
      await shootPose(tester);
      await shootPose(tester);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(find.byType(QCHintChip), findsOneWidget);
      expect(
        find.text('Turn your right side to the camera'),
        // The chip AND the side overlay hint carry the same canonical
        // retake copy (flows/vault.md table, verbatim).
        findsWidgets,
      );

      // Fix the side scenario, then retake: the flow re-enters Pose 2 —
      // never Pose 1.
      camera.sideSampleId = 'pass_side';
      await tester.tap(find.text('Retake'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Pose 2 of 2'), findsOneWidget);
      expect(find.text('Pose 1 of 2'), findsNothing);

      // One side shot later the session resolves — the kept front frame
      // rides the resubmit.
      await shootPose(tester);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(find.byType(CaptureResults), findsOneWidget);
    });

    testWidgets('the side arms_position failure carries the POSE-CONTEXTUAL '
        'relaxed-arms copy', (tester) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(sideSampleId: 'qc_side_arms_position'),
      );
      await shootPose(tester);
      await shootPose(tester);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(find.byType(QCHintChip), findsOneWidget);
      expect(
        find.text('Let your arms hang relaxed at your sides'),
        findsOneWidget,
      );
      expect(
        find.text('Keep arms slightly away from your body'),
        findsNothing,
      );
    });

    testWidgets('a multi-fault frame surfaces only the FIRST table failure', (
      tester,
    ) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(frontSampleId: 'multi_fault'),
      );
      await shootPose(tester);
      await shootPose(tester);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      // poor_lighting precedes blurry and too_far in the table.
      expect(find.byType(QCHintChip), findsOneWidget);
      expect(
        find.text('Find better lighting — avoid strong backlight'),
        findsOneWidget,
      );
      expect(find.text('Hold steady and retake'), findsNothing);
      expect(find.text('Move closer — fill more of the frame'), findsNothing);
    });

    testWidgets('the QC dead end offers the manual fallback', (tester) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(frontSampleId: 'qc_too_far'),
      );
      await shootPose(tester);
      await shootPose(tester);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      await tester.tap(find.text('Enter manually instead'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualEntryScreen), findsOneWidget);
    });
  });

  group('camera permission denied (flows/vault.md §1 edge case)', () {
    testWidgets('renders the explainer EmptyState with the manual fallback', (
      tester,
    ) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(permissionDenied: true),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Camera access is off — enable it in Settings to measure '
          'automatically',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Enter manually instead'));
      await tester.pumpAndSettle();
      expect(find.byType(ManualEntryScreen), findsOneWidget);
    });
  });

  group('dev QC selector (the documented §10 dev seam)', () {
    testWidgets('lists both pose groups and swaps the fake camera scenario '
        'per pose', (tester) async {
      // Tall surface: both pose groups render without scrolling.
      tester.view.physicalSize = const Size(390, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final camera = CameraServiceFake();
      await bootToCapture(tester, camera: camera);

      await tester.tap(find.bySemanticsLabel('QC scenario'));
      await tester.pumpAndSettle();
      expect(find.text('Pose 1 — front'), findsOneWidget);
      expect(find.text('Pose 2 — side'), findsOneWidget);
      expect(find.text('Pass — frontal, well lit'), findsOneWidget);

      await tester.tap(find.text('QC fail — two bodies in frame'));
      await tester.pumpAndSettle();
      expect(camera.frontSampleId, 'qc_multiple_bodies');
      expect(camera.sideSampleId, 'pass_side');
      expect(find.byType(CaptureScreen), findsOneWidget);

      // The side group drives the SIDE pose's sample.
      await tester.tap(find.bySemanticsLabel('QC scenario'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('QC fail — arms not relaxed (clearance 8% > 5%)'),
      );
      await tester.pumpAndSettle();
      expect(camera.sideSampleId, 'qc_side_arms_position');
      expect(camera.frontSampleId, 'qc_multiple_bodies');
    });
  });

  testWidgets('keeps content clear of notch and status-bar top insets '
      '(immersive viewfinder chrome)', (tester) async {
    applyNotchedView(tester);
    await bootToCapture(tester);
    // Viewfinder — the immersive over-media bar: full-bleed is
    // intentional, but the chrome CONTENT must still clear the notch.
    await expectContentClearOfTopInsets(tester);
  });
}

/// Serves every dev seed EXCEPT the vault sessions — the no-height-on-file
/// user (first capture ever): the catalog still resolves so QC scenarios
/// evaluate by rule.
class _NoVaultSeedBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.endsWith('vault_sessions.json')) {
      throw FlutterError('Unable to load asset: $key');
    }
    return rootBundle.load(key);
  }
}
