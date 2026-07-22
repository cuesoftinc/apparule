import 'package:apparule/src/core/ui/guide_page.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/capture_screen.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// The C6 guide (M-8/M-10 canvas-first rebuild): five GuidePage steps —
/// intro · get ready · phone setup · front pose · side pose — through
/// one parameterized widget with the canvas-re-keyed ARB copy;
/// completion persists the skip flag, Skip renders only on a REVISIT.
void main() {
  Future<void> bootToGuide(
    WidgetTester tester, {
    Map<String, Object> preferences = const <String, Object>{},
  }) async {
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      preferences: preferences,
    );
    routerOf(tester).go(const CaptureGuideRoute().location);
    await tester.pumpAndSettle();
  }

  GuideStep stepOf(WidgetTester tester) =>
      tester.widget<GuidePage>(find.byType(GuidePage)).step;

  testWidgets('pages through the five canvas steps (M-10: side pose is '
      'step 5)', (tester) async {
    await bootToGuide(tester);

    expect(find.byType(CaptureGuideScreen), findsOneWidget);
    expect(find.text('Guide A-Z'), findsOneWidget);
    expect(
      find.text(
        'How to take your body measurement accurately — two photos '
        '(front and side) plus your height is all it takes.',
      ),
      findsOneWidget,
    );
    expect(stepOf(tester), GuideStep.intro);
    expect(find.bySemanticsLabel('Step 1 of 5'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Get ready'), findsOneWidget);
    expect(stepOf(tester), GuideStep.ready);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Set your phone up'), findsOneWidget);
    expect(stepOf(tester), GuideStep.setup);
    // The NEW canvas lighting bullet — teaches the poor_lighting/blurry
    // QC checks before the camera opens (529:8935).
    expect(
      find.text(
        'Face the light — even, bright lighting keeps the photo sharp.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Strike the pose'), findsOneWidget);
    expect(stepOf(tester), GuideStep.poseFront);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    // The side pose is the LAST step (540:9172 — M-10 two-pose canon).
    expect(find.text('Turn to the side'), findsOneWidget);
    expect(stepOf(tester), GuideStep.poseSide);
    expect(
      find.text('Turn right 90 degrees — your side to the camera.'),
      findsOneWidget,
    );
    expect(
      find.text('Stand straight with your arms relaxed at your sides.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Step 5 of 5'), findsOneWidget);
    expect(find.text('Start capture'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('completing the guide persists the flag and enters capture', (
    tester,
  ) async {
    await bootToGuide(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Start capture'));
    // The replacement opens on the viewfinder — pump past the camera
    // init microtask AND the route transition (MI-12 pulses forever;
    // never settle).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.byType(CaptureGuideScreen), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('capture_guide_seen'), isTrue);
  });

  testWidgets('Skip is absent on the first run', (tester) async {
    await bootToGuide(tester);

    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('Skip renders on a REVISIT only and jumps to capture', (
    tester,
  ) async {
    await bootToGuide(
      tester,
      preferences: <String, Object>{'capture_guide_seen': true},
    );

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CaptureScreen), findsOneWidget);
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToGuide(tester);
    await expectContentClearOfTopInsets(tester);
  });
}
