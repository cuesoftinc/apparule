import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/presentation/first_action_screen.dart';
import 'package:apparule/src/features/feed/presentation/explore_screen.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C1b — the post-signup interstitial (canvas 266:2; pages.md C1b): the
/// personalised welcome, the two choice cards (→ C6 capture entry / →
/// C3 explore) and "Skip for now"; every exit flips the persisted flag
/// so later sign-ins skip the screen.
void main() {
  Future<void> bootToFirstAction(
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
    routerOf(tester).go(const FirstActionRoute().location);
    await tester.pumpAndSettle();
  }

  testWidgets('renders the canvas copy with the profile first name', (
    tester,
  ) async {
    await bootToFirstAction(tester);

    expect(find.text('Welcome, Kiki 👋'), findsOneWidget);
    expect(
      find.text('Two ways to start — you can always do the other later.'),
      findsOneWidget,
    );
    expect(find.text('Take your first measurement'), findsOneWidget);
    expect(find.text('One photo — about a minute'), findsOneWidget);
    expect(find.text('Explore outfits'), findsOneWidget);
    expect(find.text('Browse Lagos designers first'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('the measurement card enters the C6 capture flow (guide on '
      'first run)', (tester) async {
    await bootToFirstAction(tester);

    await tester.tap(find.text('Take your first measurement'));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureGuideScreen), findsOneWidget);
  });

  testWidgets('the explore card lands on C3', (tester) async {
    await bootToFirstAction(tester);

    await tester.tap(find.text('Explore outfits'));
    await tester.pumpAndSettle();

    expect(find.byType(ExploreScreen), findsOneWidget);
  });

  testWidgets('Skip for now goes home and marks the flag — a later /signin '
      'visit skips C1b', (tester) async {
    await bootToFirstAction(tester);

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeFeedScreen), findsOneWidget);

    // The persisted flag now short-circuits the C1b redirect.
    routerOf(tester).go(const SignInRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(FirstActionScreen), findsNothing);
    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToFirstAction(tester);
    await expectContentClearOfTopInsets(tester);
  });
}
