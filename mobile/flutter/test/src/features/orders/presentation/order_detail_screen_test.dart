import 'dart:async';

import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/core/ui/timeline_connector.dart';
import 'package:apparule/src/core/ui/typing_bubble.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/button_state.dart';
import '../../../../helpers/notched.dart';
import '../../../../helpers/reduced_motion.dart';

/// C8 detail over the seeded fake: MI-14 TimelineConnector timeline,
/// frozen snapshot, MI-15 payment box (paying state, just-paid escrow
/// explainer), danger-ladder actions (armed sheets born DISARMED —
/// CLASS 5 arming tests, never defect-encoding tests), decline/dispute
/// surfacing, MI-17 typing hold-back and the MI-18 optimistic thread.
/// Every action asserts the REPOSITORY transition, not just the rendered
/// pill. 390px width; reduced motion (the MI-14 pulse repeats — the
/// primitives' §5 fallback renders static, motion is unit-covered).
void main() {
  Future<OrderRepositoryFake> bootToOrder(
    WidgetTester tester,
    String orderId, {
    String viewer = 'kiki.adeyemi',
    OrderRepositoryFake? repository,
  }) async {
    disableTestAnimations(tester);
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final orders = repository ?? OrderRepositoryFake(viewer: viewer);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      orderRepository: orders,
    );
    routerOf(tester).go(OrderDetailRoute(id: orderId).location);
    await tester.pumpAndSettle();
    return orders;
  }

  Finder pill(String label) => find.descendant(
    of: find.byType(StatusPill),
    matching: find.text(label),
  );

  Finder inSheet(String label) => find.descendant(
    of: find.byType(Sheet),
    matching: find.text(label),
  );

  group('#APR-1042 (in_progress, customer)', () {
    testWidgets('renders timeline, escrow box and the frozen snapshot', (
      tester,
    ) async {
      await bootToOrder(tester, 'req-apr-1042');

      // MI-14 timeline: the four events + the pending next step, on the
      // TimelineConnector ladder (D41).
      expect(find.text('Requested'), findsWidgets);
      expect(find.text('Quote sent · ₦45,000'), findsOneWidget);
      expect(find.text('Payment held in escrow'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byType(TimelineConnector), findsWidgets);

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

    testWidgets('the dispute sheet is born DISARMED: the destructive '
        'confirm stays disabled until a reason is deliberately picked '
        '(CLASS 5)', (tester) async {
      final repository = await bootToOrder(tester, 'req-apr-1042');

      await tester.tap(find.text('Something wrong?'));
      await tester.pumpAndSettle();
      expect(find.byType(Sheet), findsOneWidget);
      expect(find.text('What happened?'), findsOneWidget);
      expect(find.text('Drag photos here or browse'), findsOneWidget);

      // Born disarmed: placeholder up, CTA dead (D11).
      expect(find.text('What went wrong?'), findsOneWidget);
      expect(buttonEnabled(tester, 'Open dispute'), isFalse);

      // A deliberate pick arms the confirm.
      await tester.tap(find.text('What went wrong?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not as described').last);
      await tester.pumpAndSettle();
      expect(buttonEnabled(tester, 'Open dispute'), isTrue);

      await tester.tap(find.text('Open dispute'));
      await tester.pumpAndSettle();

      expect(pill('Disputed'), findsOneWidget);
      expect(find.text('Funds frozen'), findsOneWidget);
      final order = await repository.order('req-apr-1042');
      expect(order.status, OrderStatus.disputed);
      // The PICKED reason — never a silently-applied default.
      expect(order.dispute?.reason, DisputeReason.notAsDescribed);
    });
  });

  testWidgets('#APR-1033 (quoted): the MI-15 pay CTA holds escrow', (
    tester,
  ) async {
    final repository = await bootToOrder(tester, 'req-apr-1033');

    expect(find.text('Reject quote'), findsOneWidget); // quiet-danger
    await tester.tap(find.text('Pay ₦40,000'));
    await tester.pumpAndSettle();

    expect(pill('Paid'), findsOneWidget);
    expect(find.text('₦40,000 held in escrow'), findsOneWidget);
    expect(
      (await repository.order('req-apr-1033')).payment?.state,
      PaymentState.held,
    );
    // MI-15 (D64): the escrow explainer expands on the JUST-PAID moment.
    expect(
      find.textContaining('Your money stays with Apparule'),
      findsOneWidget,
    );
  });

  testWidgets('MI-15 (D07): paying drives the inline spinner state and a '
      'double tap cannot double-charge', (tester) async {
    final repository = _GatedPayRepository();
    await bootToOrder(tester, 'req-apr-1033', repository: repository);

    await tester.tap(find.text('Pay ₦40,000'));
    await tester.pump();

    // The box is in the `paying` cell while the future is in flight —
    // the CTA swaps its label for the inline spinner.
    expect(find.text('Confirming payment with your bank…'), findsOneWidget);
    final payingCta = find.byWidgetPredicate(
      (widget) => widget is Button && widget.label == 'Paying',
    );
    expect(payingCta, findsOneWidget);
    expect(tester.widget<Button>(payingCta).loading, isTrue);

    // Second tap while in flight: guarded no-op — no unhandled
    // paid→paid StateError, no second charge.
    await tester.tap(payingCta, warnIfMissed: false);
    await tester.pump();
    expect(repository.payCalls, 1);

    repository.payGate.complete();
    await tester.pumpAndSettle();
    expect(pill('Paid'), findsOneWidget);
    expect(find.text('₦40,000 held in escrow'), findsOneWidget);
  });

  testWidgets('MI-15 (D64): a seeded paid order does NOT show the '
      'first-payment escrow explainer on re-entry', (tester) async {
    await bootToOrder(tester, 'req-apr-1036');

    expect(find.text('₦35,000 held in escrow'), findsOneWidget);
    expect(
      find.textContaining('Your money stays with Apparule'),
      findsNothing,
    );
  });

  testWidgets('#APR-1044 (shipped): confirm delivery passes the ARMED '
      'sheet before the payout releases (D08)', (tester) async {
    final repository = await bootToOrder(tester, 'req-apr-1044');

    expect(find.text('Shipped · GIG-5567-LAG'), findsOneWidget);
    await tester.tap(find.text('Confirm delivery'));
    await tester.pumpAndSettle();

    // The armed rung: nothing released yet, the sheet explains the
    // irreversible release.
    expect(find.byType(Sheet), findsOneWidget);
    expect(find.text('Confirm delivery?'), findsOneWidget);
    expect(
      find.textContaining('This releases the payout to tunde.o'),
      findsOneWidget,
    );
    expect(
      (await repository.order('req-apr-1044')).status,
      OrderStatus.shipped,
    );

    await tester.tap(inSheet('Confirm delivery'));
    await tester.pumpAndSettle();

    expect(pill('Delivered'), findsOneWidget);
    expect(find.text('Payment released'), findsOneWidget);
    expect(
      (await repository.order('req-apr-1044')).payment?.state,
      PaymentState.released,
    );
  });

  testWidgets('#APR-1031 (requested): withdraw is armed — Cancel keeps '
      'the order, confirm cancels it (D09)', (tester) async {
    final repository = await bootToOrder(tester, 'req-apr-1031');

    await tester.tap(find.text('Withdraw request'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw this request?'), findsOneWidget);

    // Backing out of the armed sheet leaves the order untouched.
    await tester.tap(inSheet('Cancel'));
    await tester.pumpAndSettle();
    expect(
      (await repository.order('req-apr-1031')).status,
      OrderStatus.requested,
    );

    await tester.tap(find.text('Withdraw request'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('Withdraw request'));
    await tester.pumpAndSettle();

    expect(pill('Cancelled'), findsOneWidget);
    expect(
      (await repository.order('req-apr-1031')).status,
      OrderStatus.cancelled,
    );
  });

  testWidgets('#APR-1033 (quoted): the customer row reads "Reject quote" '
      'and the armed sheet names the rejection (D09)', (tester) async {
    final repository = await bootToOrder(tester, 'req-apr-1033');

    expect(find.text('Withdraw request'), findsNothing);
    await tester.tap(find.text('Reject quote'));
    await tester.pumpAndSettle();
    expect(find.text('Reject this quote?'), findsOneWidget);

    await tester.tap(inSheet('Reject quote'));
    await tester.pumpAndSettle();

    expect(pill('Cancelled'), findsOneWidget);
    expect(
      (await repository.order('req-apr-1033')).status,
      OrderStatus.cancelled,
    );
  });

  testWidgets('D39: a failed lifecycle transition surfaces the failure '
      'toast instead of a silent StateError', (tester) async {
    final repository = await bootToOrder(tester, 'req-apr-1044');
    repository.failNext = StateError('transition raced');

    await tester.tap(find.text('Confirm delivery'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet('Confirm delivery'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong — try again.'), findsOneWidget);
    expect(pill('Shipped'), findsOneWidget); // nothing moved
    expect(
      (await repository.order('req-apr-1044')).status,
      OrderStatus.shipped,
    );
  });

  group('designer view (viewer=tunde.o / amara.designs)', () {
    testWidgets('#APR-1031: the decline sheet is born DISARMED and the '
        'note rides the repository call (D04/D12)', (tester) async {
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

      // Born disarmed (D12): placeholder up, destructive CTA dead —
      // "reason required" never degrades to "default silently applied".
      expect(find.text('Why are you declining?'), findsOneWidget);
      expect(
        buttonEnabled(tester, 'Decline request', within: find.byType(Sheet)),
        isFalse,
      );

      await tester.tap(find.text('Why are you declining?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Budget too low').last);
      await tester.pumpAndSettle();
      expect(
        buttonEnabled(tester, 'Decline request', within: find.byType(Sheet)),
        isTrue,
      );

      // D04: the optional note is captured, not silently discarded.
      await tester.enterText(
        find.descendant(
          of: find.byType(Sheet),
          matching: find.byType(TextField),
        ),
        'Half my usual rate — sorry!',
      );
      await tester.tap(inSheet('Decline request'));
      await tester.pumpAndSettle();

      expect(pill('Declined'), findsOneWidget);
      final order = await repository.order('req-apr-1031');
      expect(order.status, OrderStatus.declined);
      expect(order.declineReason, DeclineReason.budgetTooLow);
      expect(order.declineNote, 'Half my usual rate — sorry!');
    });

    testWidgets('#APR-1033: requote while quoted — Edit quote opens the '
        'prefilled sheet and replaces the amount (D06)', (tester) async {
      final repository = await bootToOrder(
        tester,
        'req-apr-1033',
        viewer: 'amara.designs',
      );

      // The designer finally has a path to edit a live quote.
      expect(find.text('Quote sent · ₦40,000'), findsWidgets);
      await tester.tap(find.text('Edit quote'));
      await tester.pumpAndSettle();

      expect(find.text('Send a quote'), findsOneWidget);
      // Prefilled with the CURRENT quote (naira units).
      expect(find.text('40000'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(Sheet),
          matching: find.byType(TextField),
        ),
        '52,000',
      );
      await tester.pumpAndSettle();
      await tester.tap(inSheet('Send quote'));
      await tester.pumpAndSettle();

      final order = await repository.order('req-apr-1033');
      // Requote replaces the amount WITHOUT a transition
      // (flows/designer.md §2).
      expect(order.status, OrderStatus.quoted);
      expect(order.quoteCents, 5200000);
      expect(pill('Quoted'), findsOneWidget);
    });

    testWidgets('#APR-1042: mark shipped goes through the ship sheet — '
        'tracking is finally enterable (D10)', (tester) async {
      final repository = await bootToOrder(
        tester,
        'req-apr-1042',
        viewer: 'amara.designs',
      );

      await tester.tap(find.text('Mark shipped'));
      await tester.pumpAndSettle();
      expect(find.text('Tracking number (optional)'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(Sheet),
          matching: find.byType(TextField),
        ),
        'GIG-9001-LAG',
      );
      // The sheet title shares the CTA's label — target the Button.
      await tester.tap(
        find.descendant(
          of: find.byType(Sheet),
          matching: find.widgetWithText(Button, 'Mark shipped'),
        ),
      );
      await tester.pumpAndSettle();

      expect(pill('Shipped'), findsOneWidget);
      final order = await repository.order('req-apr-1042');
      expect(order.status, OrderStatus.shipped);
      expect(order.tracking, 'GIG-9001-LAG');
      expect(find.text('Shipped · GIG-9001-LAG'), findsOneWidget);
    });
  });

  group('D43: decline/dispute reasons surface to the counterparty', () {
    testWidgets('#APR-1012 (declined) renders the reason line', (
      tester,
    ) async {
      await bootToOrder(tester, 'req-apr-1012');
      expect(
        find.text('Declined: Fully booked this month'),
        findsOneWidget,
      );
    });

    testWidgets('#APR-1018 (disputed) renders reason + detail', (
      tester,
    ) async {
      await bootToOrder(tester, 'req-apr-1018');
      expect(
        find.textContaining('Dispute open (Not as described)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Colours differ from the reference photos'),
        findsOneWidget,
      );
    });
  });

  group('MI-17/MI-18 thread', () {
    testWidgets('the scripted reply hides behind the typing pulse before '
        'revealing (D13)', (tester) async {
      await bootToOrder(tester, 'req-apr-1031');

      await tester.enterText(
        find.byType(TextField),
        'Can you match the post fabric?',
      );
      await tester.tap(find.bySemanticsLabel('Send message'));
      // Optimistic frame: the own bubble is already on stage (D40).
      await tester.pump();
      expect(
        find.textContaining('Can you match the post fabric?'),
        findsOneWidget,
      );

      // Server echo lands; the counterparty is "responding…" — the
      // scripted reply is HELD BACK, not popped in the same frame.
      await tester.pump();
      await tester.pump();
      expect(find.byType(TypingBubble), findsOneWidget);
      expect(find.textContaining('Got it — thanks!'), findsNothing);

      // The MI-17 hold-back elapses: pulse down, reply up.
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(TypingBubble), findsNothing);
      expect(find.textContaining('Got it — thanks!'), findsOneWidget);
    });

    testWidgets('a failed send keeps the text on stage with retry '
        '(D40, MI-18)', (tester) async {
      final repository = await bootToOrder(tester, 'req-apr-1042');
      repository.failNext = StateError('network down');

      await tester.enterText(find.byType(TextField), 'Any progress photos?');
      await tester.tap(find.bySemanticsLabel('Send message'));
      await tester.pumpAndSettle();

      // The text SURVIVES in the failed bubble, with the retry
      // affordance — never silently discarded.
      expect(find.textContaining('Any progress photos?'), findsOneWidget);
      expect(find.text("Couldn't send — tap to retry"), findsOneWidget);

      // Retry re-sends the same body (the seam has disarmed).
      await tester.tap(find.text("Couldn't send — tap to retry"));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Any progress photos?'), findsOneWidget);
      expect(find.text("Couldn't send — tap to retry"), findsNothing);
      // Flush the MI-17 hold-back the successful send scheduled.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToOrder(tester, 'req-apr-1042');
    await expectContentClearOfTopInsets(tester);
  });
}

/// D07's pending-future gate: `pay` blocks on [payGate] so the test can
/// hold the MI-15 `paying` state on stage and prove the double-tap guard
/// (the CLASS 2 Completer recipe).
class _GatedPayRepository extends OrderRepositoryFake {
  final Completer<void> payGate = Completer<void>();
  int payCalls = 0;

  @override
  Future<Order> pay(String id) async {
    payCalls++;
    await payGate.future;
    return super.pay(id);
  }
}
