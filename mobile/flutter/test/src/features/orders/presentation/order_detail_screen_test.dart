import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C8 detail over the seeded fake: timeline, frozen snapshot, MI-15
/// payment box, danger-ladder actions, dispute/decline sheets, MI-17
/// thread. Every action asserts the REPOSITORY transition, not just the
/// rendered pill. 390px width.
void main() {
  Future<OrderRepositoryFake> bootToOrder(
    WidgetTester tester,
    String orderId, {
    String viewer = 'kiki.adeyemi',
  }) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repository = OrderRepositoryFake(viewer: viewer);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      orderRepository: repository,
    );
    routerOf(tester).go(OrderDetailRoute(id: orderId).location);
    await tester.pumpAndSettle();
    return repository;
  }

  Finder pill(String label) => find.descendant(
    of: find.byType(StatusPill),
    matching: find.text(label),
  );

  group('#APR-1042 (in_progress, customer)', () {
    testWidgets('renders timeline, escrow box and the frozen snapshot', (
      tester,
    ) async {
      await bootToOrder(tester, 'req-apr-1042');

      // MI-14 timeline: the four events + the pending next step.
      expect(find.text('Requested'), findsWidgets);
      expect(find.text('Quote sent · ₦45,000'), findsOneWidget);
      expect(find.text('Payment held in escrow'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // MI-15 escrow-held box.
      expect(find.text('₦45,000 held in escrow'), findsOneWidget);

      // The immutable snapshot (order-lifecycle.md §2 privacy core).
      expect(find.text('Measurement snapshot'), findsOneWidget);
      expect(find.text('42.5 cm'), findsOneWidget);
      expect(find.text('36.8 cm'), findsOneWidget);

      // MI-17 thread narrates the order.
      expect(
        find.textContaining('Fabric cut today'),
        findsOneWidget,
      );
    });

    testWidgets('the counterparty line opens their C9 profile', (
      tester,
    ) async {
      await bootToOrder(tester, 'req-apr-1042');

      // Web OrderDetailView parity: the counterparty links their
      // profile (live-QA sweep — the line rendered as static text).
      await tester.tap(find.bySemanticsLabel('View amara.designs profile'));
      await tester.pumpAndSettle();

      final profile = tester.widget<PublicProfileScreen>(
        find.byType(PublicProfileScreen),
      );
      expect(profile.username, 'amara.designs');
    });

    testWidgets('the dispute flow: link → sheet → destructive confirm → '
        'disputed + payout frozen', (tester) async {
      final repository = await bootToOrder(tester, 'req-apr-1042');

      await tester.tap(find.text('Something wrong?'));
      await tester.pumpAndSettle();
      expect(find.byType(Sheet), findsOneWidget);
      expect(find.text('What happened?'), findsOneWidget);
      expect(find.text('Drag photos here or browse'), findsOneWidget);

      await tester.tap(find.text('Open dispute'));
      await tester.pumpAndSettle();

      expect(pill('Disputed'), findsOneWidget);
      expect(find.text('Funds frozen'), findsOneWidget);
      final order = await repository.order('req-apr-1042');
      expect(order.status, OrderStatus.disputed);
      expect(order.dispute?.reason, DisputeReason.sizeWrong);
    });
  });

  testWidgets('#APR-1033 (quoted): the MI-15 pay CTA holds escrow', (
    tester,
  ) async {
    final repository = await bootToOrder(tester, 'req-apr-1033');

    expect(find.text('Withdraw request'), findsOneWidget); // quiet-danger
    await tester.tap(find.text('Pay ₦40,000'));
    await tester.pumpAndSettle();

    expect(pill('Paid'), findsOneWidget);
    expect(find.text('₦40,000 held in escrow'), findsOneWidget);
    expect(
      (await repository.order('req-apr-1033')).payment?.state,
      PaymentState.held,
    );
  });

  testWidgets('#APR-1044 (shipped): confirming delivery releases the '
      'payout', (tester) async {
    final repository = await bootToOrder(tester, 'req-apr-1044');

    expect(find.text('Shipped · GIG-5567-LAG'), findsOneWidget);
    await tester.tap(find.text('Confirm delivery'));
    await tester.pumpAndSettle();

    expect(pill('Delivered'), findsOneWidget);
    expect(find.text('Payment released'), findsOneWidget);
    expect(
      (await repository.order('req-apr-1044')).payment?.state,
      PaymentState.released,
    );
  });

  testWidgets('#APR-1031 (requested): withdraw is the quiet-danger rung', (
    tester,
  ) async {
    final repository = await bootToOrder(tester, 'req-apr-1031');

    await tester.tap(find.text('Withdraw request'));
    await tester.pumpAndSettle();

    expect(pill('Cancelled'), findsOneWidget);
    expect(
      (await repository.order('req-apr-1031')).status,
      OrderStatus.cancelled,
    );
  });

  testWidgets('designer view (#APR-1031, viewer=tunde.o): decline sheet '
      'records the reason', (tester) async {
    final repository = await bootToOrder(
      tester,
      'req-apr-1031',
      viewer: 'tunde.o',
    );

    expect(find.text('Customer · kiki.adeyemi'), findsOneWidget);
    expect(find.text('Send quote'), findsOneWidget);

    await tester.tap(find.text('Decline request'));
    await tester.pumpAndSettle();
    expect(find.text('Decline this request'), findsOneWidget);
    expect(find.text('Fully booked this month'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(Sheet),
        matching: find.text('Decline request'),
      ),
    );
    await tester.pumpAndSettle();

    expect(pill('Declined'), findsOneWidget);
    final order = await repository.order('req-apr-1031');
    expect(order.status, OrderStatus.declined);
    expect(order.declineReason, DeclineReason.workload);
  });

  testWidgets('the MI-17 composer sends and receives the scripted reply', (
    tester,
  ) async {
    await bootToOrder(tester, 'req-apr-1031');

    await tester.enterText(
      find.byType(TextField),
      'Can you match the post fabric?',
    );
    await tester.tap(find.bySemanticsLabel('Send message'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Can you match the post fabric?'),
      findsOneWidget,
    );
    expect(find.textContaining('Got it — thanks!'), findsOneWidget);
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToOrder(tester, 'req-apr-1042');
    await expectContentClearOfTopInsets(tester);
  });
}
