import 'package:apparule/src/core/ui/choice_card.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/presentation/designer_onboarding_screen.dart';
import 'package:apparule/src/features/measurements/presentation/capture_screen.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';

/// The ➕ create chooser (M-11, canvas 548:2725): the centre tab opens a
/// two-option sheet — "Take measurements" preserves the guide-first-run
/// capture entry; "Post an outfit" is designer-gated (C13 for
/// non-designers; designers see the fit-data subtitle and take the same
/// route until C15 ships).
void main() {
  Future<void> bootAndOpenChooser(
    WidgetTester tester, {
    String viewer = 'kiki.adeyemi',
    Map<String, Object> preferences = const <String, Object>{},
  }) async {
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      earningsRepository: EarningsRepositoryFake(
        viewer: viewer,
        resolveDelay: Duration.zero,
      ),
      preferences: preferences,
    );
    await tester.tap(find.bySemanticsLabel('Create'));
    await tester.pumpAndSettle();
  }

  testWidgets('the ➕ tab opens the two-option chooser sheet (never a '
      'direct camera push)', (tester) async {
    await bootAndOpenChooser(tester);

    expect(find.text('Create'), findsWidgets);
    expect(find.byType(ChoiceCard), findsNWidgets(2));
    expect(find.text('Take measurements'), findsOneWidget);
    expect(find.text('Two photos — about a minute'), findsOneWidget);
    expect(find.text('Post an outfit'), findsOneWidget);
    // No capture surface yet — the chooser interposes.
    expect(find.byType(CaptureScreen), findsNothing);
    expect(find.byType(CaptureGuideScreen), findsNothing);
  });

  testWidgets('Take measurements → the guide on FIRST run (the persisted '
      'flag logic survives behind the chooser)', (tester) async {
    await bootAndOpenChooser(tester);

    await tester.tap(find.text('Take measurements'));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureGuideScreen), findsOneWidget);
  });

  testWidgets('Take measurements → straight to capture once the guide flag '
      'is set', (tester) async {
    await bootAndOpenChooser(
      tester,
      preferences: <String, Object>{'capture_guide_seen': true},
    );

    await tester.tap(find.text('Take measurements'));
    // The viewfinder animates (MI-12) — bounded pumps.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.byType(CaptureGuideScreen), findsNothing);
  });

  testWidgets('Post an outfit (non-designer) carries the become-a-designer '
      'subtitle and routes to C13', (tester) async {
    await bootAndOpenChooser(tester);

    expect(find.text('Become a designer to post'), findsOneWidget);
    expect(find.text('Share a look with its fit data'), findsNothing);

    await tester.tap(find.text('Post an outfit'));
    await tester.pumpAndSettle();

    expect(find.byType(DesignerOnboardingScreen), findsOneWidget);
  });

  testWidgets('Post an outfit (designer) carries the fit-data subtitle and '
      'takes the same route until C15 ships', (tester) async {
    await bootAndOpenChooser(tester, viewer: 'amara.designs');

    expect(find.text('Share a look with its fit data'), findsOneWidget);
    expect(find.text('Become a designer to post'), findsNothing);

    await tester.tap(find.text('Post an outfit'));
    await tester.pumpAndSettle();

    expect(find.byType(DesignerOnboardingScreen), findsOneWidget);
  });
}
