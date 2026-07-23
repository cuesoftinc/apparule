import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/domain/thread_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_repository.g.dart';

/// Abstract order repository — C5/C8 (mobile-implementation.md §3).
/// Every mutation is a REAL lifecycle transition validated against the
/// order-lifecycle.md §1 table (the web mock store's semantics); illegal
/// moves throw [StateError], they never silently no-op.
abstract class OrderRepository {
  /// The signed-in user's orders, both roles, newest activity first (C8).
  Future<List<Order>> orders();

  /// One order by id.
  Future<Order> order(String id);

  /// The order's message thread, oldest first (SOC-005, MI-17).
  Future<List<ThreadMessage>> messages(String orderId);

  /// Appends to the thread; the counterparty sends one scripted reply per
  /// thread (web store parity — gives MI-17 a real payoff over fakes).
  Future<ThreadMessage> sendMessage(String orderId, String body);

  /// C5 submit: freezes the measurement snapshot the caller picked
  /// (order-lifecycle.md §1 — later vault changes never mutate an order).
  /// The post/designer summary arrives as plain values because
  /// repositories never reference each other (mobile-implementation.md
  /// §3) — the C5 ViewModel bridges the post domain into this call.
  Future<Order> submitRequest({
    required OrderPostSummary post,
    required OrderParty designer,
    required OrderSnapshot snapshot,
    required DeliveryAddress delivery,
    String notes,
    int? budgetCents,
    DateTime? targetDate,
  });

  /// Pre-fills C5 step 2 from the most recent order (data-model.md §6.3 —
  /// no saved address book in v1); `null` when no orders exist.
  Future<DeliveryAddress?> lastDeliveryAddress();

  /// Customer pays the quote — escrow hold (quoted → paid).
  Future<Order> pay(String id);

  /// Customer confirms delivery — payout releases (shipped → delivered).
  Future<Order> confirmDelivery(String id);

  /// Customer withdraws (requested) or rejects the quote (quoted).
  Future<Order> cancel(String id);

  /// Either party opens a dispute — payout freezes
  /// (paid/in_progress/shipped → disputed).
  Future<Order> openDispute(String id, DisputeReason reason, {String? detail});

  /// Designer quotes (requested → quoted; requote while quoted replaces
  /// the amount without a transition, flows/designer.md §2).
  Future<Order> quote(String id, int quoteCents, {required DateTime dueAt});

  /// Designer declines with a required reason and an optional note to
  /// the customer (requested → declined; pages.md B3 "reason enum +
  /// optional note" — web `orders-repo.decline(id, reason, note)`).
  Future<Order> decline(String id, DeclineReason reason, {String? note});

  /// Designer starts work (paid → in_progress).
  Future<Order> startProgress(String id);

  /// Designer ships, tracking optional (in_progress → shipped).
  Future<Order> ship(String id, {String? tracking});
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) => throw UnimplementedError(
  'orderRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
