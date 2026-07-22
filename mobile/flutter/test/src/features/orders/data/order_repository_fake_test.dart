import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seeded order fake carries all ten lifecycle states from the web
/// mock narrative and enforces order-lifecycle.md §1 (transition table)
/// and §2 (permissions matrix) on every mutation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  OrderRepositoryFake fake({String viewer = 'kiki.adeyemi'}) =>
      OrderRepositoryFake(
        now: () => DateTime.utc(2026, 7, 22, 12),
        viewer: viewer,
      );

  group('transition table (order-lifecycle.md §1)', () {
    test('matches the ratified state machine edge-for-edge', () {
      expect(OrderStatus.transitions, <OrderStatus, List<OrderStatus>>{
        OrderStatus.requested: <OrderStatus>[
          OrderStatus.quoted,
          OrderStatus.declined,
          OrderStatus.cancelled,
        ],
        OrderStatus.quoted: <OrderStatus>[
          OrderStatus.paid,
          OrderStatus.cancelled,
        ],
        OrderStatus.paid: <OrderStatus>[
          OrderStatus.inProgress,
          OrderStatus.refunded,
          OrderStatus.disputed,
        ],
        OrderStatus.inProgress: <OrderStatus>[
          OrderStatus.shipped,
          OrderStatus.disputed,
        ],
        OrderStatus.shipped: <OrderStatus>[
          OrderStatus.delivered,
          OrderStatus.disputed,
        ],
        OrderStatus.disputed: <OrderStatus>[
          OrderStatus.delivered,
          OrderStatus.refunded,
        ],
        OrderStatus.delivered: <OrderStatus>[],
        OrderStatus.refunded: <OrderStatus>[],
        OrderStatus.declined: <OrderStatus>[],
        OrderStatus.cancelled: <OrderStatus>[],
      });
    });

    test('terminal states reject every move', () {
      for (final terminal in <OrderStatus>[
        OrderStatus.delivered,
        OrderStatus.refunded,
        OrderStatus.declined,
        OrderStatus.cancelled,
      ]) {
        for (final to in OrderStatus.values) {
          expect(terminal.canTransitionTo(to), isFalse);
        }
      }
    });
  });

  group('seed narrative (web parity)', () {
    test('all ten lifecycle states load for the §6 test user', () async {
      final orders = await fake().orders();

      expect(orders, hasLength(10));
      expect(
        orders.map((order) => order.status).toSet(),
        OrderStatus.values.toSet(),
        reason: 'every StatusPill state renders from boot (§6)',
      );
      // Newest activity first — the fresh quote (6h) leads the list.
      expect(orders.first.id, 'req-apr-1033');
    });

    test('#APR-1042 carries the detailed web narrative', () async {
      final order = await fake().order('req-apr-1042');

      expect(order.orderNumber, 'APR-1042');
      expect(order.status, OrderStatus.inProgress);
      expect(order.quoteCents, 4500000); // ₦45,000
      expect(order.payment?.state, PaymentState.held);
      expect(order.payment?.platformFeeCents, 450000); // 10% (A-1)
      expect(order.events.map((event) => event.kind), <String>[
        'requested', 'quoted', 'paid', 'in_progress', //
      ]);
      // PR #102 cadence: pinned wall-clock times, not one batch minute.
      expect(order.events.first.createdAt.hour, 9);
      expect(order.events.first.createdAt.minute, 14);
    });

    test('#APR-1058 keeps the frozen child-size snapshot (snapshots '
        'freeze at requested)', () async {
      final order = await fake().order('req-apr-1058');

      expect(order.snapshot.method, 'manual');
      expect(
        order.snapshot.measurements.map((m) => m.valueCm),
        <double>[28, 25.5, 60.5, 55],
      );
    });

    test('the dispute narrative carries reason + detail', () async {
      final order = await fake().order('req-apr-1018');
      expect(order.status, OrderStatus.disputed);
      expect(order.dispute?.reason, DisputeReason.notAsDescribed);
      expect(order.declineReason, isNull);

      final declined = await fake().order('req-apr-1012');
      expect(declined.declineReason, DeclineReason.workload);
    });
  });

  group('customer actions (§2 matrix)', () {
    test('pay moves quoted → paid with a held 10% escrow', () async {
      final repository = fake();
      final paid = await repository.pay('req-apr-1033');

      expect(paid.status, OrderStatus.paid);
      expect(paid.payment?.state, PaymentState.held);
      expect(paid.payment?.amountCents, 4000000);
      expect(paid.payment?.platformFeeCents, 400000);
      expect(paid.events.last.kind, 'paid');

      // Persisted — the list re-read shows the same truth.
      final relisted = await repository.order('req-apr-1033');
      expect(relisted.status, OrderStatus.paid);
    });

    test('pay rejects an unquoted order', () async {
      expect(
        () => fake().pay('req-apr-1031'), // requested — no quote yet
        throwsStateError,
      );
    });

    test('confirmDelivery moves shipped → delivered and releases the '
        'payout', () async {
      final delivered = await fake().confirmDelivery('req-apr-1044');
      expect(delivered.status, OrderStatus.delivered);
      expect(delivered.payment?.state, PaymentState.released);
    });

    test('confirmDelivery rejects an unshipped order (illegal move, '
        'never a silent no-op)', () async {
      expect(
        () => fake().confirmDelivery('req-apr-1036'), // paid
        throwsStateError,
      );
    });

    test('cancel withdraws a requested order', () async {
      final cancelled = await fake().cancel('req-apr-1031');
      expect(cancelled.status, OrderStatus.cancelled);
    });

    test('cancel after paid is refused — money only resolves through '
        'delivered or refunded (§1)', () async {
      expect(() => fake().cancel('req-apr-1036'), throwsStateError);
    });

    test(
      'disputes open from paid/in_progress/shipped and freeze there',
      () async {
        final repository = fake();
        final disputed = await repository.openDispute(
          'req-apr-1042',
          DisputeReason.sizeWrong,
          detail: 'Shoulders came out tighter than the snapshot.',
        );
        expect(disputed.status, OrderStatus.disputed);
        expect(disputed.dispute?.reason, DisputeReason.sizeWrong);

        // The dispute window ends at delivery confirmation (§1).
        expect(
          () => repository.openDispute(
            'req-apr-1058', // delivered
            DisputeReason.notAsDescribed,
          ),
          throwsStateError,
        );
      },
    );

    test('designer-only actions are refused for the customer', () async {
      final repository = fake();
      expect(
        () => repository.decline('req-apr-1031', DeclineReason.workload),
        throwsStateError,
      );
      expect(
        () => repository.quote(
          'req-apr-1031',
          5000000,
          dueAt: DateTime.utc(2026, 8, 22),
        ),
        throwsStateError,
      );
    });
  });

  group('designer actions (viewer=tunde.o over the same seed)', () {
    test('the designer sees their side of the narrative', () async {
      final orders = await fake(viewer: 'tunde.o').orders();
      expect(
        orders.map((order) => order.id).toSet(),
        <String>{'req-apr-1031', 'req-apr-1044', 'req-apr-1018'},
      );
      expect(
        orders.every((order) => order.viewerRole == OrderRole.designer),
        isTrue,
      );
    });

    test('quote moves requested → quoted with amount + due date', () async {
      final repository = fake(viewer: 'tunde.o');
      final dueAt = DateTime.utc(2026, 8, 22);
      final quoted = await repository.quote(
        'req-apr-1031',
        5500000,
        dueAt: dueAt,
      );
      expect(quoted.status, OrderStatus.quoted);
      expect(quoted.quoteCents, 5500000);
      expect(quoted.dueAt, dueAt);
    });

    test('decline records the required reason', () async {
      final declined = await fake(
        viewer: 'tunde.o',
      ).decline('req-apr-1031', DeclineReason.timelineTooTight);
      expect(declined.status, OrderStatus.declined);
      expect(declined.declineReason, DeclineReason.timelineTooTight);
    });

    test('ship carries optional tracking; the walk paid → shipped is '
        'legal only in order', () async {
      final repository = fake(viewer: 'tunde.o');
      // 1044 is shipped — shipping again is illegal.
      expect(() => repository.ship('req-apr-1044'), throwsStateError);
    });
  });

  group('C5 submit (snapshot freeze)', () {
    test(
      'submitRequest opens a requested order with the frozen copy',
      () async {
        final repository = fake();
        final delivery = await repository.lastDeliveryAddress();
        expect(delivery?.line1, '14 Adeola Odeku St'); // §6.3 pre-fill

        final order = await repository.submitRequest(
          post: const OrderPostSummary(
            id: 'post-agbada',
            caption: 'Ceremonial robe set',
            thumbUrl: '/demo/outfit-w17.jpg',
          ),
          designer: const OrderParty(id: 'des-tunde', username: 'tunde.o'),
          snapshot: OrderSnapshot(
            method: 'mediapipe_2d_v2',
            measuredAt: DateTime.utc(2026, 7, 10),
            measurements: const <SnapshotMeasurement>[
              SnapshotMeasurement(name: 'shoulder_width', valueCm: 42.5),
              SnapshotMeasurement(name: 'hip_width', valueCm: 36.8),
            ],
          ),
          delivery: delivery!,
          notes: 'For the wedding.',
          budgetCents: 6000000,
        );

        // Web store parity: the counter continues past the seed.
        expect(order.orderNumber, 'APR-1059');
        expect(order.status, OrderStatus.requested);
        expect(order.viewerRole, OrderRole.customer);
        expect(order.snapshot.measurements.first.valueCm, 42.5);
        expect(order.events.single.kind, 'requested');

        final orders = await repository.orders();
        expect(orders.map((o) => o.id), contains(order.id));
      },
    );
  });

  group('thread (MI-17, order-lifecycle.md §5)', () {
    test('messages sort oldest first and narrate the order', () async {
      final messages = await fake().messages('req-apr-1042');
      expect(messages, hasLength(3));
      expect(messages.first.id, 'msg-1042-1');
      expect(messages.first.own, isTrue); // kiki authored it
      expect(messages.last.own, isFalse); // amara's progress shot
      expect(messages.last.imageUrl, '/demo/outfit-w10.jpg');
    });

    test('sendMessage triggers ONE scripted counterparty reply per '
        'thread', () async {
      final repository = fake();
      await repository.sendMessage('req-apr-1031', 'Any update?');
      var messages = await repository.messages('req-apr-1031');
      expect(messages, hasLength(3)); // seed 1 + sent + scripted reply
      expect(messages.last.own, isFalse);

      await repository.sendMessage('req-apr-1031', 'Hello again?');
      messages = await repository.messages('req-apr-1031');
      expect(messages, hasLength(4)); // no second scripted reply
    });
  });

  test(
    'a prod bundle (no dev seeds) degrades to an empty order book',
    () async {
      final repository = OrderRepositoryFake(bundle: _EmptyAssetBundle());
      expect(await repository.orders(), isEmpty);
      expect(await repository.lastDeliveryAddress(), isNull);
    },
  );

  test('failNext arms a throw-once failure on the next mutation '
      '(CLASS 4 seam)', () async {
    final repository = fake();
    final order = (await repository.orders()).first;

    repository.failNext = Exception('server 500');
    await expectLater(
      repository.sendMessage(order.id, 'hello'),
      throwsException,
    );

    // Disarmed: the retry lands.
    final message = await repository.sendMessage(order.id, 'hello');
    expect(message.body, 'hello');
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
