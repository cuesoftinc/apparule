import 'package:apparule/src/core/data/seed_json.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/domain/thread_message.dart';
import 'package:flutter/services.dart';

/// Seed-backed fake (mobile-implementation.md §6): all ten lifecycle
/// states from the web mock seed (same order numbers, quotes, events,
/// frozen snapshots and thread cadence as `web/src/mocks/seed.ts`), with
/// the web store's transition semantics — every mutation runs through the
/// order-lifecycle.md §1 table and the §2 permissions matrix; illegal
/// moves throw instead of mutating. State persists for the provider's
/// keepAlive lifetime, so paying a quote on C8 updates the same order the
/// list re-reads.
class OrderRepositoryFake implements OrderRepository {
  /// [viewer] switches the seeded role perspective over the SAME
  /// narrative: the default is the §6 test user (`kiki.adeyemi`,
  /// customer side); tests pass a designer username (`tunde.o`) to walk
  /// the designer surfaces (quote/decline) — the web store's
  /// username-scoped method shape.
  OrderRepositoryFake({
    AssetBundle? bundle,
    DateTime Function()? now,
    this.viewer = 'kiki.adeyemi',
  }) : _bundle = bundle ?? PlatformAssetBundle(),
       _now = now ?? DateTime.now;

  static const String _ordersAsset = 'assets/seed/dev/orders.json';

  /// Web store parity: the seed's counter starts past its last seeded
  /// order number.
  static const int _firstLocalOrderNumber = 1059;

  final AssetBundle _bundle;
  final DateTime Function() _now;

  /// The signed-in username the §2 permissions matrix evaluates against.
  final String viewer;

  bool _loaded = false;
  final List<Order> _orders = <Order>[];
  final List<ThreadMessage> _messages = <ThreadMessage>[];
  final Set<String> _autoReplied = <String>{};
  int _orderSequence = 0;
  int _messageSequence = 0;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final now = _now();
    if (await loadSeedJson(_bundle, _ordersAsset) case final seed?) {
      for (final entry in seed['orders'] as List<dynamic>) {
        _orders.add(_orderFromSeed(entry as Map<String, dynamic>, now));
      }
      for (final entry in seed['messages'] as List<dynamic>) {
        _messages.add(_messageFromSeed(entry as Map<String, dynamic>, now));
      }
    }
  }

  Order _orderFromSeed(Map<String, dynamic> json, DateTime now) {
    final customer = _partyFromSeed(json['customer'] as Map<String, dynamic>);
    final designer = _partyFromSeed(json['designer'] as Map<String, dynamic>);
    final post = json['post'] as Map<String, dynamic>;
    final snapshot = json['snapshot'] as Map<String, dynamic>;
    final payment = json['payment'] as Map<String, dynamic>?;
    final dispute = json['dispute'] as Map<String, dynamic>?;
    final dueInDays = json['due_in_days'] as num?;
    final events = <OrderEvent>[
      for (final event in json['events'] as List<dynamic>)
        OrderEvent(
          kind: (event as Map<String, dynamic>)['kind'] as String,
          actor: event['actor'] as String,
          createdAt: seedDaysAgoAt(
            now,
            event['days_ago'] as num,
            event['time'] as String?,
          ),
        ),
    ];
    // The order (and the snapshot freeze) exists from the moment it was
    // requested — anchored to the first event (web seed parity).
    final requestedAt = events.first.createdAt;
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      post: OrderPostSummary(
        id: post['id'] as String,
        caption: post['caption'] as String,
        thumbUrl: post['thumb_url'] as String,
      ),
      customer: customer,
      designer: designer,
      status: OrderStatus.fromWireName(json['status'] as String),
      viewerRole: _roleFor(customer, designer),
      notes: json['notes'] as String? ?? '',
      budgetCents: (json['budget_cents'] as num?)?.toInt(),
      quoteCents: (json['quote_cents'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'NGN',
      dueAt: dueInDays == null ? null : seedDaysAgo(now, -dueInDays),
      tracking: json['tracking'] as String?,
      declineReason: switch (json['decline_reason'] as String?) {
        null => null,
        final reason => DeclineReason.fromWireName(reason),
      },
      dispute: dispute == null
          ? null
          : OrderDispute(
              reason: DisputeReason.fromWireName(
                dispute['reason'] as String,
              ),
              detail: dispute['detail'] as String?,
            ),
      delivery: _deliveryFromSeed(json['delivery'] as Map<String, dynamic>),
      snapshot: OrderSnapshot(
        method: snapshot['method'] as String,
        measuredAt: seedDaysAgo(now, snapshot['measured_days_ago'] as num),
        measurements: <SnapshotMeasurement>[
          for (final measurement in snapshot['measurements'] as List<dynamic>)
            SnapshotMeasurement(
              name: (measurement as Map<String, dynamic>)['name'] as String,
              valueCm: (measurement['value_cm'] as num).toDouble(),
            ),
        ],
      ),
      events: events,
      payment: payment == null
          ? null
          : OrderPayment(
              state: PaymentState.fromWireName(payment['state'] as String),
              amountCents: (payment['amount_cents'] as num).toInt(),
              platformFeeCents: (payment['platform_fee_cents'] as num).toInt(),
            ),
      createdAt: requestedAt,
    );
  }

  static OrderParty _partyFromSeed(Map<String, dynamic> json) => OrderParty(
    id: json['id'] as String,
    username: json['username'] as String,
    avatarUrl: json['avatar_url'] as String?,
  );

  static DeliveryAddress _deliveryFromSeed(Map<String, dynamic> json) =>
      DeliveryAddress(
        recipientName: json['recipient_name'] as String,
        phone: json['phone'] as String,
        line1: json['line1'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        country: json['country'] as String,
      );

  ThreadMessage _messageFromSeed(Map<String, dynamic> json, DateTime now) {
    final authorId = json['author_id'] as String;
    return ThreadMessage(
      id: json['id'] as String,
      orderId: json['request_id'] as String,
      authorId: authorId,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      own: _isViewerAccount(authorId),
      createdAt: seedDaysAgoAt(
        now,
        json['days_ago'] as num,
        json['time'] as String?,
      ),
    );
  }

  OrderRole _roleFor(OrderParty customer, OrderParty designer) =>
      designer.username == viewer ? OrderRole.designer : OrderRole.customer;

  /// The seeded account/designer-profile ids the viewer authors under
  /// (web threads carry `acc-*` for customers, `des-*` for designers).
  bool _isViewerAccount(String authorId) {
    for (final order in _orders) {
      if (order.customer.username == viewer && order.customer.id == authorId) {
        return true;
      }
      if (order.designer.username == viewer && order.designer.id == authorId) {
        return true;
      }
    }
    return false;
  }

  Order _orderById(String id) => _orders.firstWhere(
    (order) => order.id == id,
    orElse: () {
      throw StateError('Order not found: $id');
    },
  );

  void _replace(Order updated) {
    final index = _orders.indexWhere((order) => order.id == updated.id);
    _orders[index] = updated;
  }

  /// The single transition gate (web store `transition()` parity): every
  /// status move validates against order-lifecycle.md §1 and appends its
  /// timeline event.
  Order _transition(Order order, OrderStatus to, String actor) {
    if (!order.status.canTransitionTo(to)) {
      throw StateError(
        'Cannot move an order from ${order.status.wireName} to '
        '${to.wireName} (order-lifecycle.md §1)',
      );
    }
    return order.copyWith(
      status: to,
      events: <OrderEvent>[
        ...order.events,
        OrderEvent(kind: to.wireName, actor: actor, createdAt: _now()),
      ],
    );
  }

  /// §2 permissions matrix: the viewer must hold [role] on this order.
  Order _orderAs(String id, OrderRole role) {
    final order = _orderById(id);
    if (order.viewerRole != role) {
      throw StateError(
        'Only the ${role.name} may perform this action '
        '(order-lifecycle.md §2)',
      );
    }
    return order;
  }

  @override
  Future<List<Order>> orders() async {
    await _ensureLoaded();
    final visible =
        _orders
            .where(
              (order) =>
                  order.customer.username == viewer ||
                  order.designer.username == viewer,
            )
            .toList()
          // Newest activity first — the C8 list leads with what moved.
          ..sort(
            (a, b) => b.events.last.createdAt.compareTo(
              a.events.last.createdAt,
            ),
          );
    return List<Order>.unmodifiable(visible);
  }

  @override
  Future<Order> order(String id) async {
    await _ensureLoaded();
    return _orderById(id);
  }

  @override
  Future<List<ThreadMessage>> messages(String orderId) async {
    await _ensureLoaded();
    return <ThreadMessage>[
      for (final message in _messages)
        if (message.orderId == orderId) message,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<ThreadMessage> sendMessage(String orderId, String body) async {
    await _ensureLoaded();
    final order = _orderById(orderId);
    final ownParty = order.viewerRole == OrderRole.designer
        ? order.designer
        : order.customer;
    final message = ThreadMessage(
      id: 'msg-local-${++_messageSequence}',
      orderId: orderId,
      authorId: ownParty.id,
      body: body,
      own: true,
      createdAt: _now(),
    );
    _messages.add(message);
    // Scripted counterparty reply, once per thread (web store parity —
    // MI-17's "responding…" indicator gets a real payoff over fakes).
    if (order.viewerRole == OrderRole.customer && _autoReplied.add(orderId)) {
      _messages.add(
        ThreadMessage(
          id: 'msg-local-${++_messageSequence}',
          orderId: orderId,
          authorId: order.designer.id,
          body: "Got it — thanks! I'll take a look and reply properly shortly.",
          own: false,
          createdAt: _now().add(const Duration(milliseconds: 1)),
        ),
      );
    }
    return message;
  }

  @override
  Future<Order> submitRequest({
    required OrderPostSummary post,
    required OrderParty designer,
    required OrderSnapshot snapshot,
    required DeliveryAddress delivery,
    String notes = '',
    int? budgetCents,
    DateTime? targetDate,
  }) async {
    await _ensureLoaded();
    final now = _now();
    final order = Order(
      id: 'req-local-${++_orderSequence}',
      orderNumber: 'APR-${_firstLocalOrderNumber + _orderSequence - 1}',
      post: post,
      // The §6 signed-in test user submits as the customer.
      customer: OrderParty(id: 'acc-kiki', username: viewer),
      designer: designer,
      status: OrderStatus.requested,
      viewerRole: OrderRole.customer,
      notes: notes,
      budgetCents: budgetCents,
      delivery: delivery,
      // Frozen copy — later vault changes never mutate the order.
      snapshot: snapshot,
      events: <OrderEvent>[
        OrderEvent(kind: 'requested', actor: 'customer', createdAt: now),
      ],
      createdAt: now,
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<DeliveryAddress?> lastDeliveryAddress() async {
    await _ensureLoaded();
    Order? newest;
    for (final order in _orders) {
      if (order.customer.username != viewer || order.delivery == null) {
        continue;
      }
      if (newest == null || order.createdAt.isAfter(newest.createdAt)) {
        newest = order;
      }
    }
    return newest?.delivery;
  }

  @override
  Future<Order> pay(String id) async {
    await _ensureLoaded();
    final order = _orderAs(id, OrderRole.customer);
    final quote = order.quoteCents;
    if (quote == null) throw StateError('Order has no quote to pay');
    // charge.success lands directly in held (Paystack capture model);
    // 10% platform fee (A-1, ratified).
    final updated = _transition(order, OrderStatus.paid, 'customer').copyWith(
      payment: OrderPayment(
        state: PaymentState.held,
        amountCents: quote,
        platformFeeCents: (quote * 0.1).round(),
      ),
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<Order> confirmDelivery(String id) async {
    await _ensureLoaded();
    final order = _orderAs(id, OrderRole.customer);
    var updated = _transition(order, OrderStatus.delivered, 'customer');
    if (updated.payment case final payment?) {
      updated = updated.copyWith(
        payment: payment.copyWith(state: PaymentState.released),
      );
    }
    _replace(updated);
    return updated;
  }

  @override
  Future<Order> cancel(String id) async {
    await _ensureLoaded();
    final order = _orderAs(id, OrderRole.customer);
    final updated = _transition(order, OrderStatus.cancelled, 'customer');
    _replace(updated);
    return updated;
  }

  @override
  Future<Order> openDispute(
    String id,
    DisputeReason reason, {
    String? detail,
  }) async {
    await _ensureLoaded();
    // Either party (order-lifecycle.md §2).
    final order = _orderById(id);
    final updated =
        _transition(
          order,
          OrderStatus.disputed,
          order.viewerRole.name,
        ).copyWith(
          dispute: OrderDispute(reason: reason, detail: detail),
        );
    _replace(updated);
    return updated;
  }

  @override
  Future<Order> quote(
    String id,
    int quoteCents, {
    required DateTime dueAt,
  }) async {
    await _ensureLoaded();
    if (quoteCents <= 0) throw StateError('Quote must be positive');
    var order = _orderAs(id, OrderRole.designer);
    if (order.status != OrderStatus.quoted) {
      // Requote while `quoted` replaces the amount without a transition
      // (flows/designer.md §2); otherwise requested → quoted.
      order = _transition(order, OrderStatus.quoted, 'designer');
    }
    final updated = order.copyWith(quoteCents: quoteCents, dueAt: dueAt);
    _replace(updated);
    return updated;
  }

  @override
  Future<Order> decline(String id, DeclineReason reason) async {
    await _ensureLoaded();
    final order = _orderAs(id, OrderRole.designer);
    final updated = _transition(
      order,
      OrderStatus.declined,
      'designer',
    ).copyWith(declineReason: reason);
    _replace(updated);
    return updated;
  }

  @override
  Future<Order> startProgress(String id) async {
    await _ensureLoaded();
    final order = _orderAs(id, OrderRole.designer);
    final updated = _transition(order, OrderStatus.inProgress, 'designer');
    _replace(updated);
    return updated;
  }

  @override
  Future<Order> ship(String id, {String? tracking}) async {
    await _ensureLoaded();
    final order = _orderAs(id, OrderRole.designer);
    final updated = _transition(
      order,
      OrderStatus.shipped,
      'designer',
    ).copyWith(tracking: tracking ?? order.tracking);
    _replace(updated);
    return updated;
  }
}
