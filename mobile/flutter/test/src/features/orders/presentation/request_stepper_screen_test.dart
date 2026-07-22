import 'package:apparule/src/core/ui/banner.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C5 over the seeded fakes: the vault snapshot picker (C6/C7
/// integration), freshness warnings, §6.3 delivery pre-fill, review,
/// submit (snapshot freeze per order-lifecycle.md §1), success → C8.
/// 390px width.
void main() {
  Future<OrderRepositoryFake> bootToStepper(
    WidgetTester tester, {
    MeasurementRepositoryFake? measurementRepository,
  }) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final orders = OrderRepositoryFake();
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
      'ladder; stale selections warn', (tester) async {
    await bootToStepper(tester);

    expect(find.text('New request · 1 of 3'), findsOneWidget);
    expect(find.text('Pick a measurement snapshot'), findsOneWidget);
    // The three seeded sessions (web vault parity): fresh scan, aging
    // manual, stale scan.
    expect(pillText('Fresh'), findsOneWidget);
    expect(pillText('Aging'), findsOneWidget);
    expect(pillText('Stale'), findsOneWidget);
    expect(find.textContaining('shoulder 42.5 · hip 36.8'), findsOneWidget);

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
  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToStepper(tester);
    expectNoContentInTopInset(tester);
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
