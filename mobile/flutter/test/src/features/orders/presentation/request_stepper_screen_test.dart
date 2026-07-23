import 'package:apparule/src/core/ui/banner.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/core/ui/step_slide.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/domain/order_exception.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_screen.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:apparule/src/features/orders/presentation/request_stepper_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/button_state.dart';
import '../../../../helpers/notched.dart';
import '../../../../helpers/reduced_motion.dart';

/// C5 over the seeded fakes: the vault snapshot picker (C6/C7
/// integration, newest preselected — D63), freshness warnings, §6.3
/// delivery pre-fill + the D14 REQUIRED_DELIVERY gate + D15 recipient,
/// D44 soft warnings, review (D65 expandable snapshot), submit (snapshot
/// freeze per order-lifecycle.md §1; D38 failure banner), success → C8.
/// 390px width; reduced motion (success navigates into the C8 detail,
/// whose MI-14 pulse repeats).
void main() {
  Future<OrderRepositoryFake> bootToStepper(
    WidgetTester tester, {
    MeasurementRepositoryFake? measurementRepository,
    OrderRepositoryFake? orderRepository,
  }) async {
    disableTestAnimations(tester);
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final orders = orderRepository ?? OrderRepositoryFake();
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      orderRepository: orders,
      measurementRepository: measurementRepository,
    );
    routerOf(
      tester,
    ).go(const RequestRoute(postId: 'post-ankara-gown').location);
    await tester.pumpAndSettle();
    return orders;
  }

  Finder pillText(String label) => find.descendant(
    of: find.byType(StatusPill),
    matching: find.text(label),
  );

  testWidgets('step 1 lists the vault sessions across the freshness '
      'ladder with the newest PRESELECTED (D63); stale selections warn', (
    tester,
  ) async {
    await bootToStepper(tester);

    expect(find.text('New request · 1 of 3'), findsOneWidget);
    expect(find.text('Pick a measurement snapshot'), findsOneWidget);
    // The three seeded sessions (web vault parity): fresh scan, aging
    // manual, stale scan.
    expect(pillText('Fresh'), findsOneWidget);
    expect(pillText('Aging'), findsOneWidget);
    expect(pillText('Stale'), findsOneWidget);
    expect(find.textContaining('shoulder 42.5 · hip 36.8'), findsOneWidget);

    // D63 (web parity): the newest session starts selected — Continue
    // starts ready, and the MI-10 StepSlide hosts the step body.
    expect(buttonEnabled(tester, 'Continue'), isTrue);
    expect(find.byType(StepSlide), findsOneWidget);

    // Selecting the stale scan raises the freshness warning (C5 spec).
    await tester.tap(pillText('Stale'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBanner), findsOneWidget);
    expect(
      find.textContaining('over 90 days old'),
      findsOneWidget,
    );
  });

  testWidgets('the full journey: pick → details (pre-filled §6.3) → '
      'review → submit → success → view order', (tester) async {
    final orders = await bootToStepper(tester);

    // Step 1 — pick the fresh scan.
    await tester.tap(pillText('Fresh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2 — delivery pre-fills from the most recent order.
    expect(find.text('New request · 2 of 3'), findsOneWidget);
    expect(find.text('14 Adeola Odeku St'), findsOneWidget);
    expect(find.text('Lagos'), findsWidgets);
    await tester.enterText(
      find.byType(TextField).first,
      'Slightly longer sleeves, please',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 3 — review.
    expect(find.text('Review your request'), findsOneWidget);
    expect(
      find.text(
        'Ankara maxi skirt with structured waistband — amara.designs',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('scan · 2 measurements'), findsOneWidget);
    expect(find.text('Slightly longer sleeves, please'), findsOneWidget);

    // Submit — the snapshot freezes into a requested order.
    await tester.tap(find.text('Submit request'));
    await tester.pumpAndSettle();
    expect(find.text('Request sent'), findsOneWidget);
    expect(
      find.textContaining('amara.designs usually replies'),
      findsOneWidget,
    );

    final created = (await orders.orders()).singleWhere(
      (order) => order.orderNumber == 'APR-1059',
    );
    expect(created.status, OrderStatus.requested);
    expect(created.snapshot.method, 'mediapipe_2d_v2');
    expect(created.snapshot.measurements.first.valueCm, 42.5);
    expect(created.delivery?.line1, '14 Adeola Odeku St');
    // D15: the recipient rides the (pre-filled) form field, never a
    // hardcoded fallback.
    expect(created.delivery?.recipientName, 'Kiki Adeyemi');
    expect(created.notes, 'Slightly longer sleeves, please');

    // Success → C8 detail of the new order.
    await tester.tap(find.text('View order'));
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(pillText('Requested'), findsOneWidget);
  });

  testWidgets('an empty vault routes into C6 instead of a dead picker', (
    tester,
  ) async {
    await bootToStepper(
      tester,
      measurementRepository: MeasurementRepositoryFake(
        bundle: _EmptyAssetBundle(),
      ),
    );

    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.textContaining('You need a measurement session'),
      findsOneWidget,
    );
  });

  testWidgets('D14: with no pre-fill, step 2 Continue stays disabled '
      'until the whole six-field delivery set exists', (tester) async {
    // An empty order seed means no §6.3 pre-fill — the delivery form
    // starts blank, exactly the audit's blank-submit repro.
    await bootToStepper(
      tester,
      orderRepository: OrderRepositoryFake(bundle: _EmptyAssetBundle()),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('New request · 2 of 3'), findsOneWidget);

    // Blank form: the CTA is dead — a blank address can never submit.
    expect(buttonEnabled(tester, 'Continue'), isFalse);

    // D15: the recipient field is part of the form now.
    expect(find.text('Recipient name'), findsOneWidget);

    // Fill five of six — still gated.
    final fields = find.byType(TextField);
    // Order: notes · budget · recipient · line1 · city · state ·
    // country · phone.
    await tester.enterText(fields.at(2), 'Kiki Adeyemi');
    await tester.enterText(fields.at(3), '14 Adeola Odeku St');
    await tester.enterText(fields.at(4), 'Lagos');
    await tester.enterText(fields.at(5), 'Lagos');
    await tester.enterText(fields.at(6), 'NG');
    await tester.pumpAndSettle();
    expect(buttonEnabled(tester, 'Continue'), isFalse);

    // The sixth lands — the gate opens.
    await tester.enterText(fields.at(7), '+2348012345678');
    await tester.pumpAndSettle();
    expect(buttonEnabled(tester, 'Continue'), isTrue);
  });

  testWidgets('D44: a budget below the designer base price raises the '
      'soft warning — warn, never block', (tester) async {
    await bootToStepper(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // post-ankara-gown's base price is ₦45,000 — 40,000 undercuts it.
    await tester.enterText(find.byType(TextField).at(1), '40,000');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('below the designer'),
      findsOneWidget,
    );
    expect(buttonEnabled(tester, 'Continue'), isTrue); // soft — not a gate

    await tester.enterText(find.byType(TextField).at(1), '50,000');
    await tester.pumpAndSettle();
    expect(find.textContaining('below the designer'), findsNothing);
  });

  test('D44: turnaroundTight flags need-by dates inside the designer '
      'turnaround (web isTurnaroundTight parity)', () {
    final now = DateTime.utc(2026, 7, 22);
    final post = Post(
      id: 'post-x',
      designer: const PostDesigner(
        id: 'des-x',
        username: 'x',
        displayName: 'X',
      ),
      caption: 'c',
      styleTags: const <String>[],
      media: const <PostMedia>[],
      likeCount: 0,
      commentCount: 0,
      createdAt: now,
      turnaroundDays: 14,
    );
    expect(turnaroundTight(post, now.add(const Duration(days: 7)), now), true);
    expect(
      turnaroundTight(post, now.add(const Duration(days: 30)), now),
      false,
    );
    expect(turnaroundTight(post, null, now), false);
  });

  testWidgets('D38: a submit failure surfaces the error banner — '
      'duplicate_request offers View orders; the stepper state survives', (
    tester,
  ) async {
    final orders = await bootToStepper(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Generic failure first: the shared "try again" banner.
    orders.failNext = Exception('network down');
    await tester.tap(find.text('Submit request'));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong — try again.'), findsOneWidget);
    expect(find.text('Review your request'), findsOneWidget); // state kept

    // duplicate_request (flows/request.md §1): named copy + the jump.
    orders.failNext = const OrderException(OrderErrorCode.duplicateRequest);
    await tester.tap(find.text('Submit request'));
    await tester.pumpAndSettle();
    expect(
      find.text('You already have an open request for this outfit.'),
      findsOneWidget,
    );
    expect(find.text('View orders'), findsOneWidget);

    await tester.tap(find.text('View orders'));
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);
  });

  testWidgets('D65: the review step expands the frozen snapshot values '
      'for inspection before submit', (tester) async {
    await bootToStepper(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Snapshot · 2 values'), findsOneWidget);
    expect(find.text('16.7 in'), findsNothing);

    // Canonical 42.5/36.8 cm — inches display by default (A-9).
    await tester.tap(find.text('Snapshot · 2 values'));
    await tester.pumpAndSettle();
    expect(find.text('Shoulder Width'), findsOneWidget);
    expect(find.text('16.7 in'), findsOneWidget);
    expect(find.text('14.5 in'), findsOneWidget);
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToStepper(tester);
    await expectContentClearOfTopInsets(tester);
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
