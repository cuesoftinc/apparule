import 'package:apparule/src/app/app.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/ui/app_shell.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_screen.dart';
import 'package:apparule/src/features/feed/presentation/create_screen.dart';
import 'package:apparule/src/features/feed/presentation/explore_screen.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:apparule/src/features/profile/presentation/profile_screen.dart';
import 'package:apparule/src/routing/router.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Boots the full app (router included) over the fake set, optionally
/// seeded — mirrors the entrypoints' composition.
Future<void> pumpBootedApp(
  WidgetTester tester, {
  AuthRepository? authRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakeRepositoryOverrides(authRepository: authRepository),
      child: const ApparuleApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('auth redirect (mobile-implementation.md §5, live at the cutover)', () {
    testWidgets('unauthenticated boot gates every route behind /signin', (
      tester,
    ) async {
      await pumpBootedApp(tester);

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('signing in on C1 redirects into the tab shell', (
      tester,
    ) async {
      await pumpBootedApp(tester);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('an authenticated boot lands on the home feed', (tester) async {
      await pumpBootedApp(
        tester,
        authRepository: AuthRepositoryFake(
          initialSession: AuthRepositoryFake.seedSession,
        ),
      );

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('a signed-in user never sees /signin', (tester) async {
      await pumpBootedApp(
        tester,
        authRepository: AuthRepositoryFake(
          initialSession: AuthRepositoryFake.seedSession,
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ApparuleApp)),
      );
      container.read(routerProvider).go(const SignInRoute().location);
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('sign-out re-evaluates the redirect back to /signin', (
      tester,
    ) async {
      final repository = AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      );
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
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
    );

    // Home is the initial branch.
    expect(find.byType(HomeFeedScreen), findsOneWidget);

    // Tap each remaining tab via its (unselected, outline) icon — the
    // filled variant marks the active tab (IG convention, design.md §2).
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_box_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(CreateScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.receipt_long_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline).last);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });
}
