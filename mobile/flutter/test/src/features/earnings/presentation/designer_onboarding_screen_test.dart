import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/presentation/payout_account_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/button_state.dart';

/// C13 intro (D20): the create CTA is gated on the required identity
/// fields and every repository failure surfaces through `runAction` —
/// never a silent loading-flash reset (CLASS 4).
void main() {
  Future<EarningsRepositoryFake> bootToOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final earnings = EarningsRepositoryFake();
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      earningsRepository: earnings,
    );
    routerOf(tester).go(const DesignerOnboardingRoute().location);
    await tester.pumpAndSettle();
    return earnings;
  }

  testWidgets('the create CTA disables while either identity field is '
      'empty — an empty create can never fire', (tester) async {
    await bootToOnboarding(tester);

    // Prefilled from the account: ready to go.
    expect(buttonEnabled(tester, 'Create designer profile'), isTrue);

    // Clearing the display name kills the CTA (web "Display name is
    // required" parity, enforced by construction).
    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.pumpAndSettle();
    expect(buttonEnabled(tester, 'Create designer profile'), isFalse);

    await tester.enterText(find.byType(TextField).at(1), 'Kiki A.');
    await tester.pumpAndSettle();
    expect(buttonEnabled(tester, 'Create designer profile'), isTrue);
  });

  testWidgets('a repository failure surfaces the shared toast and the '
      'typed form survives (D20 / CLASS 4)', (tester) async {
    final earnings = await bootToOnboarding(tester);
    earnings.failNext = Exception('server 500');

    await tester.enterText(find.byType(TextField).at(2), 'Sustainable fits');
    await tester.tap(find.text('Create designer profile'));
    await tester.pumpAndSettle();

    // The failure toasts; nothing navigates; the bio text survives.
    expect(find.text('Something went wrong — try again.'), findsOneWidget);
    expect(find.byType(PayoutAccountScreen), findsNothing);
    expect(find.text('Sustainable fits'), findsOneWidget);
    expect((await earnings.status()).enabled, isFalse);

    // Disarmed seam: the retry succeeds and hands off to the banking
    // form (B8 intro → banking).
    await tester.tap(find.text('Create designer profile'));
    await tester.pumpAndSettle();
    expect(find.byType(PayoutAccountScreen), findsOneWidget);
    expect((await earnings.status()).enabled, isTrue);
  });
}
