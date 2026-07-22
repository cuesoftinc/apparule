import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';

/// C8 list over the seeded fake: the ten-state chip ladder, contextual
/// actions, B3 role tabs (designer side only when it exists). 390px
/// width; tall viewport so the whole seeded book builds.
void main() {
  Future<void> bootToOrders(
    WidgetTester tester, {
    OrderRepositoryFake? orderRepository,
    EarningsRepositoryFake? earningsRepository,
  }) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      orderRepository: orderRepository,
      earningsRepository: earningsRepository,
    );
    routerOf(tester).go(const OrdersRoute().location);
    await tester.pumpAndSettle();
  }

  testWidgets('renders all ten lifecycle states as chips at 390px '
      'without overflow', (tester) async {
    await bootToOrders(tester);

    // One pill per seeded state (§6: every StatusPill renders from boot).
    for (final label in <String>[
      'Requested',
      'Quoted',
      'Paid',
      'In progress',
      'Shipped',
      'Delivered',
      'Refunded',
      'Declined',
      'Disputed',
      'Cancelled',
    ]) {
      expect(
        find.descendant(
          of: find.byType(StatusPill),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: '$label chip must render from seed',
      );
    }
  });

  testWidgets('contextual actions ride the state (canvas C8-orders)', (
    tester,
  ) async {
    await bootToOrders(tester);

    expect(find.text('Pay ₦40,000'), findsOneWidget); // quoted #APR-1033
    expect(find.text('Confirm delivery'), findsOneWidget); // shipped
    expect(find.text('View updates'), findsWidgets);

    // The §6 test user is customer-only — no role tabs (B3 rule).
    expect(find.text('As designer'), findsNothing);
  });

  testWidgets('a row opens the detail', (tester) async {
    await bootToOrders(tester);

    await tester.tap(find.text('Pay ₦40,000'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
  });

  testWidgets('a designer viewer gets the role tabs over the same seed', (
    tester,
  ) async {
    await bootToOrders(
      tester,
      orderRepository: OrderRepositoryFake(viewer: 'tunde.o'),
    );

    expect(find.text('As customer'), findsOneWidget);
    expect(find.text('As designer'), findsOneWidget);

    // Customer side: tunde commissioned nothing.
    expect(find.byType(EmptyState), findsOneWidget);

    await tester.tap(find.text('As designer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Customer · kiki.adeyemi'), findsNWidgets(3));
    expect(find.text('Send quote'), findsOneWidget); // requested #APR-1031
  });

  testWidgets('a lapsed payout account raises the persistent C13 KYC '
      'banner over the designer book (canvas 205:6614)', (tester) async {
    final earnings = EarningsRepositoryFake(
      viewer: 'tunde.o',
      resolveDelay: Duration.zero,
    );
    // Pre-pump arrangement loads seed assets — real async, so it must
    // run outside the FakeAsync test zone.
    await tester.runAsync(
      () => earnings.attachPayoutAccount('058', '9999999999'),
    );
    await bootToOrders(
      tester,
      orderRepository: OrderRepositoryFake(viewer: 'tunde.o'),
      earningsRepository: earnings,
    );

    expect(
      find.text(
        'Your payout details lapsed — re-verify to keep '
        'receiving payments.',
      ),
      findsOneWidget,
    );
    expect(find.text('Re-verify'), findsOneWidget);
  });

  testWidgets('an empty order book renders the orders empty state', (
    tester,
  ) async {
    await bootToOrders(
      tester,
      orderRepository: OrderRepositoryFake(bundle: _EmptyAssetBundle()),
    );

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Discover designers'), findsOneWidget);
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
