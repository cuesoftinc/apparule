import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/capture_screen.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// The C6 guide (§10/§11 salvage): single-pose four-step flow through one
/// parameterized page widget, completion persists the skip flag, Skip
/// renders only after a first completion.
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

  testWidgets('pages through the four salvaged single-pose steps', (
    tester,
  ) async {
    await bootToGuide(tester);

    expect(find.byType(CaptureGuideScreen), findsOneWidget);
    expect(find.text('Guide A-Z'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Get ready'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Set your phone up'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    // The frontal pose is the LAST step — the legacy's fifth side-pose
    // page is retired (§10: one frontal photo is the canon).
    expect(find.text('Strike the pose'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 4 of 4'), findsOneWidget);
    expect(find.text('Start capture'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('completing the guide persists the flag and enters capture', (
    tester,
  ) async {
    await bootToGuide(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Start capture'));
    // The replacement lands on the height step (no repeating animation).
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.byType(CaptureGuideScreen), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('capture_guide_seen'), isTrue);
  });

  testWidgets('Skip is absent on the first run', (tester) async {
    await bootToGuide(tester);

    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('Skip renders after a first completion and jumps to capture', (
    tester,
  ) async {
    await bootToGuide(
      tester,
      preferences: <String, Object>{'capture_guide_seen': true},
    );

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsOneWidget);
  });

  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToGuide(tester);
    expectNoContentInTopInset(tester);
  });
}
