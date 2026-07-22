import 'package:apparule/src/core/ui/capture_overlay.dart';
import 'package:apparule/src/core/ui/capture_results.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/core/ui/processing_constellation.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/camera_service_fake.dart';
import 'package:apparule/src/features/measurements/presentation/capture_screen.dart';
import 'package:apparule/src/features/measurements/presentation/capture_view_model.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_screen.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C6 capture states over the fake camera (mobile-implementation.md §10):
/// height gate, countdown → processing → results, first-failure QC
/// rendering, permission-denied fallback, and save-to-vault (C7).
///
/// Booted through the real router (the flow navigates); bounded pumps
/// where the viewfinder/constellation animate (MI-12 never settles).
void main() {
  Future<void> bootToCapture(
    WidgetTester tester, {
    CameraServiceFake? camera,
  }) async {
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      cameraService: camera,
      preferences: <String, Object>{'capture_guide_seen': true},
    );
    routerOf(tester).go(const CaptureRoute().location);
    await tester.pumpAndSettle();
  }

  Future<void> continueToViewfinder(WidgetTester tester) async {
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Auto-capture (QA-convergence ruling: no shutter): the searching beat
  /// arms the 3-2-1 → capture fires → processing → the pipeline verdict.
  Future<void> shootThroughProcessing(WidgetTester tester) async {
    await tester.pump(kCaptureAlignDelay);
    await tester.pump();
    expect(find.bySemanticsLabel('Capturing in 3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Capturing in 2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Capturing in 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(ProcessingConstellation), findsOneWidget);
    // The fake repository's simulated pipeline latency.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
  }

  group('height step (flows/vault.md §1)', () {
    testWidgets('pre-fills from the newest session and continues to the '
        'viewfinder', (tester) async {
      await bootToCapture(tester);

      // Seeded height (kiki's sessions froze 168 cm).
      expect(find.text('168'), findsOneWidget);
      expect(find.text('Your height'), findsOneWidget);

      await continueToViewfinder(tester);
      expect(find.byType(CaptureOverlay), findsOneWidget);
      expect(find.text('Stand inside the outline'), findsOneWidget);
    });

    testWidgets('rejects heights outside 100–230 cm with the contract copy', (
      tester,
    ) async {
      await bootToCapture(tester);

      await tester.enterText(find.bySemanticsLabel('Height value'), '90');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(
        find.text('Enter a height between 100–230 cm (39–91 in).'),
        findsOneWidget,
      );
      expect(find.byType(CaptureOverlay), findsNothing);
    });

    testWidgets('the unit toggle converts the display, storage stays cm', (
      tester,
    ) async {
      await bootToCapture(tester);

      await tester.tap(find.bySemanticsLabel('Switch to in'));
      await tester.pumpAndSettle();

      // 168 cm = 66.1 in (one decimal, MI-13 display conversion).
      expect(find.text('66.1'), findsOneWidget);
    });
  });

  group('happy path (seeded pass_frontal sample)', () {
    testWidgets('countdown → processing → results with §4 confidences, '
        'save lands in the vault', (tester) async {
      await bootToCapture(tester);
      await continueToViewfinder(tester);
      await shootThroughProcessing(tester);

      // Results: scaled values (168 cm over the sample metrics) with the
      // low-confidence chip on the 0.62 hip (capture-qc.md §4).
      expect(find.byType(CaptureResults), findsOneWidget);
      expect(find.byType(MeasurementCard), findsNWidgets(2));
      expect(find.text('42.6 cm'), findsOneWidget);
      expect(find.text('35.5 cm'), findsOneWidget);
      expect(find.text('1 low confidence'), findsOneWidget);
      expect(find.text('Low confidence · 0.62'), findsOneWidget);

      await tester.tap(find.text('Save to vault'));
      await tester.pumpAndSettle();

      // C7 lists the saved session on arrival.
      expect(find.byType(VaultScreen), findsOneWidget);
      expect(find.text('Measured today'), findsOneWidget);
      expect(find.text('42.6 cm'), findsOneWidget);
    });

    testWidgets('retake from results discards and returns to the viewfinder', (
      tester,
    ) async {
      await bootToCapture(tester);
      await continueToViewfinder(tester);
      await shootThroughProcessing(tester);

      await tester.tap(find.text('Retake'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CaptureOverlay), findsOneWidget);
      expect(find.byType(CaptureResults), findsNothing);

      // The auto-capture re-arms for the next shot.
      await tester.pump(kCaptureAlignDelay);
      await tester.pump();
      expect(find.bySemanticsLabel('Capturing in 3'), findsOneWidget);
    });
  });

  group('auto-capture (QA-convergence ruling — canvas+docs, no shutter)', () {
    testWidgets('the viewfinder renders no shutter control and arms the '
        '3-2-1 by itself after the searching beat', (tester) async {
      await bootToCapture(tester);
      await continueToViewfinder(tester);

      // No capture control anywhere on the controls layer.
      expect(find.bySemanticsLabel('Capture'), findsNothing);
      expect(find.text('Stand inside the outline'), findsOneWidget);
      expect(find.bySemanticsLabel('Capturing in 3'), findsNothing);

      // ...then the countdown starts on its own.
      await tester.pump(kCaptureAlignDelay);
      await tester.pump();
      expect(find.bySemanticsLabel('Capturing in 3'), findsOneWidget);
    });

    testWidgets('announces the countdown arming and the capture firing', (
      tester,
    ) async {
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
      await continueToViewfinder(tester);
      await shootThroughProcessing(tester);

      expect(
        announcements,
        containsAllInOrder(<String>[
          'Hold still — capturing in 3',
          'Photo captured',
        ]),
      );
    });

    testWidgets('the manual-entry escape stays available on the live '
        'viewfinder', (tester) async {
      await bootToCapture(tester);
      await continueToViewfinder(tester);

      await tester.tap(find.text('Enter manually instead'));
      await tester.pumpAndSettle();

      expect(find.byType(ManualEntryScreen), findsOneWidget);
    });
  });

  group('QC failure surfacing (first-failure-only, codes 1:1)', () {
    testWidgets('a failing frame renders exactly one QCHintChip with the '
        'canonical guidance', (tester) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(sampleId: 'qc_no_body'),
      );
      await continueToViewfinder(tester);
      await shootThroughProcessing(tester);

      expect(find.byType(QCHintChip), findsOneWidget);
      expect(
        find.text('Make sure your whole body is visible'),
        findsOneWidget,
      );
      expect(find.text('Retake'), findsOneWidget);
    });

    testWidgets('a multi-fault frame surfaces only the FIRST table failure', (
      tester,
    ) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(sampleId: 'multi_fault'),
      );
      await continueToViewfinder(tester);
      await shootThroughProcessing(tester);

      // poor_lighting precedes blurry and too_far in the table.
      expect(find.byType(QCHintChip), findsOneWidget);
      expect(
        find.text('Find better lighting — avoid strong backlight'),
        findsOneWidget,
      );
      expect(find.text('Hold steady and retake'), findsNothing);
      expect(find.text('Move closer — fill more of the frame'), findsNothing);
    });

    testWidgets('retake after a QC fail returns to the viewfinder', (
      tester,
    ) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(sampleId: 'qc_blurry'),
      );
      await continueToViewfinder(tester);
      await shootThroughProcessing(tester);
      expect(find.text('Hold steady and retake'), findsOneWidget);

      await tester.tap(find.text('Retake'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(QCHintChip), findsNothing);
      expect(find.text('Stand inside the outline'), findsOneWidget);
    });

    testWidgets('the QC dead end offers the manual fallback', (tester) async {
      await bootToCapture(
        tester,
        camera: CameraServiceFake(sampleId: 'qc_too_far'),
      );
      await continueToViewfinder(tester);
      await shootThroughProcessing(tester);

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
      await continueToViewfinder(tester);
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
    testWidgets('lists the sample catalog and swaps the fake camera '
        'scenario', (tester) async {
      final camera = CameraServiceFake();
      await bootToCapture(tester, camera: camera);

      await tester.tap(find.bySemanticsLabel('QC scenario'));
      await tester.pumpAndSettle();
      expect(find.text('Pass — frontal, well lit'), findsOneWidget);

      await tester.tap(find.text('QC fail — two bodies in frame'));
      await tester.pumpAndSettle();

      expect(camera.sampleId, 'qc_multiple_bodies');
      expect(find.byType(CaptureScreen), findsOneWidget);
    });
  });

  testWidgets('keeps content clear of notch and status-bar top insets '
      '(height step + immersive viewfinder)', (tester) async {
    applyNotchedView(tester);
    await bootToCapture(tester);
    // Height step — the sub bar.
    await expectContentClearOfTopInsets(tester);

    // Viewfinder — the immersive over-media bar: full-bleed is
    // intentional, but the chrome CONTENT must still clear the notch.
    await continueToViewfinder(tester);
    await expectContentClearOfTopInsets(tester);
  });
}
