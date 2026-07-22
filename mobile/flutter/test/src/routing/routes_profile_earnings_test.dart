import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/presentation/designer_onboarding_screen.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_screen.dart';
import 'package:apparule/src/features/earnings/presentation/payout_account_screen.dart';
import 'package:apparule/src/features/profile/presentation/account_data_screen.dart';
import 'package:apparule/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_screen.dart';
import 'package:apparule/src/features/profile/presentation/notification_settings_screen.dart';
import 'package:apparule/src/features/profile/presentation/privacy_settings_screen.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:apparule/src/features/profile/presentation/settings_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/boot_app.dart';

/// The profile/earnings wave's routes: typed locations, deep-link
/// resolution (settings subs stack the root; C12 stacks the profile),
/// and the C13 onboarding → payout walk end-to-end over the fakes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  AuthRepositoryFake signedIn() =>
      AuthRepositoryFake(initialSession: AuthRepositoryFake.seedSession);

  test('typed routes carry their paths', () {
    expect(const EditProfileRoute().location, '/profile/edit');
    expect(
      const PublicProfileRoute(username: 'amara.designs').location,
      '/profile/amara.designs',
    );
    expect(
      const FollowersRoute(username: 'amara.designs').location,
      '/profile/amara.designs/followers',
    );
    expect(
      const FollowingRoute(username: 'kiki.adeyemi').location,
      '/profile/kiki.adeyemi/following',
    );
    expect(const SettingsRoute().location, '/settings');
    expect(
      const NotificationSettingsRoute().location,
      '/settings/notifications',
    );
    expect(const PrivacySettingsRoute().location, '/settings/privacy');
    expect(const AccountDataRoute().location, '/settings/account');
    expect(
      const DesignerOnboardingRoute().location,
      '/designer/onboarding',
    );
    expect(
      const PayoutAccountRoute().location,
      '/designer/onboarding/payout',
    );
    expect(const EarningsRoute().location, '/earnings');
  });

  testWidgets('deep links resolve their screens over the seeded fakes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(tester, authRepository: signedIn());
    final router = routerOf(tester)
      // The literal /profile/edit segment must win over :username.
      ..go(const EditProfileRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.byType(PublicProfileScreen), findsNothing);

    router.go(
      const PublicProfileRoute(username: 'amara.designs').location,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PublicProfileScreen), findsOneWidget);

    // A C12 deep link stacks the profile beneath the list.
    router.go(const FollowersRoute(username: 'amara.designs').location);
    await tester.pumpAndSettle();
    expect(find.byType(FollowListScreen), findsOneWidget);

    // Settings subs stack the root beneath.
    router.go(const NotificationSettingsRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsScreen), findsOneWidget);

    router.go(const PrivacySettingsRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(PrivacySettingsScreen), findsOneWidget);

    router.go(const AccountDataRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(AccountDataScreen), findsOneWidget);

    router.go(const SettingsRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    router.go(const EarningsRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(EarningsScreen), findsOneWidget);
  });

  testWidgets('C13 walks intro → payout → verified end-to-end over the '
      'fakes', (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final earnings = EarningsRepositoryFake(
      now: () => pinned,
      resolveDelay: Duration.zero,
    );
    await pumpBootedApp(
      tester,
      authRepository: signedIn(),
      earningsRepository: earnings,
    );
    routerOf(tester).go(const DesignerOnboardingRoute().location);
    await tester.pumpAndSettle();

    // Intro (canvas 204:1140): headline, bullets, prefilled form.
    expect(
      find.text('Post outfits. Get commissioned. Get paid.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, 'kiki.adeyemi'),
      findsOneWidget,
    );
    expect(
      find.text('Your page: apparule.cuesoft.io/kiki.adeyemi'),
      findsOneWidget,
    );

    await tester.tap(find.text('Create designer profile'));
    await tester.pumpAndSettle();

    // B8: intro hands off to the banking form.
    expect(find.byType(PayoutAccountScreen), findsOneWidget);
    expect((await earnings.status()).enabled, isTrue);

    // Pick the bank from the option sheet.
    await tester.tap(find.text('Select your bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GTBank'));
    await tester.pumpAndSettle();

    // A resolvable number confirms the holder name (uppercased).
    await tester.enterText(find.byType(TextField), '0123454521');
    await tester.pumpAndSettle();
    expect(find.text('KIKI ADEYEMI'), findsOneWidget);
    expect(
      find.text('Account name matches your profile'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save payout account'));
    await tester.pumpAndSettle();
    expect(find.text('Payout account saved'), findsOneWidget);
    expect(
      (await earnings.status()).payoutAccount?.accountLast4,
      '4521',
    );
  });

  testWidgets('the C13 failed state offers retry + the support link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final earnings = EarningsRepositoryFake(
      now: () => pinned,
      resolveDelay: Duration.zero,
    );
    // Pre-pump arrangement loads seed assets — real async, so it must
    // run outside the FakeAsync test zone.
    await tester.runAsync(
      () => earnings.enableDesigner(
        username: 'kiki.adeyemi',
        displayName: 'Kiki Adeyemi',
      ),
    );
    await pumpBootedApp(
      tester,
      authRepository: signedIn(),
      earningsRepository: earnings,
    );
    routerOf(tester).go(const PayoutAccountRoute().location);
    await tester.pumpAndSettle();

    expect(find.byType(DesignerOnboardingScreen), findsNothing);
    await tester.tap(find.text('Select your bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zenith Bank'));
    await tester.pumpAndSettle();

    // The deterministic 00-prefix mismatch script.
    await tester.enterText(find.byType(TextField), '0012345678');
    await tester.pumpAndSettle();

    expect(find.text("We couldn't verify that account"), findsOneWidget);
    expect(
      find.text('Check the bank and account number, then try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry verification'), findsOneWidget);
    expect(
      find.text('Still stuck after a few tries? Contact support'),
      findsOneWidget,
    );
  });
}
