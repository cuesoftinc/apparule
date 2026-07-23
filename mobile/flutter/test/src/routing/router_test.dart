import 'package:apparule/src/core/ui/app_shell.dart';
import 'package:apparule/src/core/ui/tab_bar.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/presentation/first_action_screen.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_screen.dart';
import 'package:apparule/src/features/feed/presentation/explore_screen.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:apparule/src/features/measurements/presentation/capture_screen.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_screen.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:apparule/src/features/profile/presentation/profile_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/boot_app.dart';

AuthRepositoryFake _signedIn() =>
    AuthRepositoryFake(initialSession: AuthRepositoryFake.seedSession);

void main() {
  group('auth redirect (mobile-implementation.md §5, live at the cutover)', () {
    testWidgets('unauthenticated boot gates every route behind /signin', (
      tester,
    ) async {
      await pumpBootedApp(tester);

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('a FIRST sign-in on C1 hands off to the C1b interstitial', (
      tester,
    ) async {
      await pumpBootedApp(tester);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(FirstActionScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('a returning sign-in redirects straight into the tab shell', (
      tester,
    ) async {
      await pumpBootedApp(
        tester,
        preferences: <String, Object>{'first_action_seen': true},
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('an authenticated boot lands on the home feed', (tester) async {
      await pumpBootedApp(tester, authRepository: _signedIn());

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('a signed-in user never sees /signin', (tester) async {
      await pumpBootedApp(
        tester,
        authRepository: _signedIn(),
        preferences: <String, Object>{'first_action_seen': true},
      );

      routerOf(tester).go(const SignInRoute().location);
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('sign-out re-evaluates the redirect back to /signin', (
      tester,
    ) async {
      final repository = _signedIn();
      await pumpBootedApp(tester, authRepository: repository);
      expect(find.byType(HomeFeedScreen), findsOneWidget);

      await repository.signOut();
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });
  });

  testWidgets('the five tabs navigate to their branch screens', (
    tester,
  ) async {
    await pumpBootedApp(
      tester,
      authRepository: _signedIn(),
      // Past the guide's first completion — ➕ goes straight to capture.
      preferences: <String, Object>{'capture_guide_seen': true},
    );

    // Home is the initial branch.
    expect(find.byType(HomeFeedScreen), findsOneWidget);

    // Tap each remaining tab via its semantics label — the AppTabBar's
    // tabs are icon-only controls named per the named-control canon.
    Finder tab(String label) => find.descendant(
      of: find.byType(AppTabBar),
      matching: find.bySemanticsLabel(label),
    );

    await tester.tap(tab('Explore'));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);

    // ➕ is an entry gesture, not a branch switch (M-11): it opens the
    // create chooser sheet; "Take measurements" pushes the full-screen
    // capture flow over the shell.
    await tester.tap(tab('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take measurements'));
    // Bounded pumps: the viewfinder silhouette pulses (MI-12), so
    // pumpAndSettle would never settle on the capture screen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CaptureScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);

    await tester.tap(tab('Orders'));
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);

    await tester.tap(tab('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(tab('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });

  group('C6 capture routing (mobile-implementation.md §10)', () {
    testWidgets('➕ opens the chooser; Take measurements → the guide on '
        'first run (no persisted flag)', (tester) async {
      await pumpBootedApp(tester, authRepository: _signedIn());

      await tester.tap(
        find.descendant(
          of: find.byType(AppTabBar),
          matching: find.bySemanticsLabel('Create'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take measurements'));
      await tester.pumpAndSettle();

      expect(find.byType(CaptureGuideScreen), findsOneWidget);
      expect(find.byType(CaptureScreen), findsNothing);
    });

    testWidgets('/capture, /capture/guide, /capture/manual and /vault '
        'deep links resolve their screens', (tester) async {
      await pumpBootedApp(tester, authRepository: _signedIn());
      final router = routerOf(tester)..go(const CaptureRoute().location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CaptureScreen), findsOneWidget);

      router.go(const CaptureGuideRoute().location);
      await tester.pumpAndSettle();
      expect(find.byType(CaptureGuideScreen), findsOneWidget);

      router.go(const ManualEntryRoute().location);
      await tester.pumpAndSettle();
      expect(find.byType(ManualEntryScreen), findsOneWidget);

      router.go(const VaultRoute().location);
      await tester.pumpAndSettle();
      expect(find.byType(VaultScreen), findsOneWidget);
    });

    testWidgets('typed capture routes carry the §5 paths', (tester) async {
      expect(const CaptureRoute().location, '/capture');
      expect(const CaptureGuideRoute().location, '/capture/guide');
      expect(const ManualEntryRoute().location, '/capture/manual');
      expect(const VaultRoute().location, '/vault');
    });
  });
}
