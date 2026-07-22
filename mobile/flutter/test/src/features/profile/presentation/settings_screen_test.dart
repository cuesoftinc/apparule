import 'package:apparule/src/core/theme/theme_mode_controller.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/notched.dart';

/// B7 settings root: identity block, creator rows off the earnings
/// status, the tri-state Appearance control persisting via the
/// persistence seam, the sub-screen rows, legal links.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Future<void> pump(
    WidgetTester tester, {
    EarningsRepositoryFake? earnings,
    ProfileRepositoryFake? profile,
  }) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpApp(
      const SettingsScreen(),
      profileRepository: profile ?? ProfileRepositoryFake(now: () => pinned),
      earningsRepository:
          earnings ??
          EarningsRepositoryFake(
            now: () => pinned,
            resolveDelay: Duration.zero,
          ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the Google identity and the section rows', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.textContaining('Kiki Adeyemi'), findsOneWidget);
    expect(
      find.textContaining('kiki.adeyemi@example.com (Google)'),
      findsOneWidget,
    );
    // Non-designer → the become-a-designer row.
    expect(find.text('Become a designer'), findsOneWidget);
    expect(
      find.text('Post outfits, get commissioned, get paid'),
      findsOneWidget,
    );
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Privacy & consent'), findsOneWidget);
    expect(find.text('Account & data'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('the tri-state theme control persists via '
      'PersistenceService', (tester) async {
    await pump(tester);

    expect(find.text('System'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(SettingsScreen));
    final container = ProviderScope.containerOf(element);
    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  testWidgets('a designer account shows the payout + earnings rows', (
    tester,
  ) async {
    await pump(
      tester,
      earnings: EarningsRepositoryFake(
        viewer: 'amara.designs',
        now: () => pinned,
        resolveDelay: Duration.zero,
      ),
    );

    expect(find.text('Designer profile active'), findsOneWidget);
    expect(find.text('Payouts verified with Paystack'), findsOneWidget);
    expect(find.text('Earnings & payouts'), findsOneWidget);
    expect(find.text('Become a designer'), findsNothing);
  });

  testWidgets('deletion-pending surfaces the persistent warn banner', (
    tester,
  ) async {
    final profile = ProfileRepositoryFake(now: () => pinned);
    // Pre-pump arrangement loads seed assets — real async, so it must
    // run outside the FakeAsync test zone.
    await tester.runAsync(profile.requestDeletion);
    await pump(tester, profile: profile);

    expect(
      find.text(
        'Account deletion requested — your data will be removed '
        'after the 30-day grace period.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await pump(tester);
    expectNoContentInTopInset(tester);
  });
}
