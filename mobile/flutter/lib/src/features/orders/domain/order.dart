import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';

/// The ten-state commission lifecycle (order-lifecycle.md §1;
/// web `OrderStatus` parity).
enum OrderStatus {
  requested('requested'),
  quoted('quoted'),
  paid('paid'),
  inProgress('in_progress'),
  shipped('shipped'),
  delivered('delivered'),
  refunded('refunded'),
  declined('declined'),
  disputed('disputed'),
  cancelled('cancelled');

  const OrderStatus(this.wireName);

  /// The order-lifecycle.md / web wire name.
  final String wireName;

  static OrderStatus fromWireName(String name) =>
      values.firstWhere((status) => status.wireName == name);

  /// Allowed transitions per order-lifecycle.md §1 — terminal states have
  /// no outgoing edges (web `ORDER_TRANSITIONS` parity; the fake gates
  /// every mutation through this table, never per-action shortcuts).
  static const Map<OrderStatus, List<OrderStatus>> transitions =
      <OrderStatus, List<OrderStatus>>{
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
      };

  bool canTransitionTo(OrderStatus to) => transitions[this]!.contains(to);
}

/// Decline reason enum (flows/designer.md §2; web `DeclineReason` parity).
enum DeclineReason {
  workload('workload'),
  outOfSpecialty('out_of_specialty'),
  budgetTooLow('budget_too_low'),
  timelineTooTight('timeline_too_tight'),
  other('other');

  const DeclineReason(this.wireName);

  final String wireName;

  static DeclineReason fromWireName(String name) =>
      values.firstWhere((reason) => reason.wireName == name);
}

/// Dispute reason enum (order-lifecycle.md §1; web `DisputeReason` parity).
enum DisputeReason {
  notReceived('not_received'),
  notAsDescribed('not_as_described'),
  sizeWrong('size_wrong'),
  other('other');

  const DisputeReason(this.wireName);

  final String wireName;

  static DisputeReason fromWireName(String name) =>
      values.firstWhere((reason) => reason.wireName == name);
}

/// Which side of the order the signed-in viewer is on (pages.md B3/C8
/// "As customer / As designer").
enum OrderRole { customer, designer }

/// One party summary (web `CommissionRequest.customer/designer` parity).
@freezed
abstract class OrderParty with _$OrderParty {
  const factory OrderParty({
    required String id,
    required String username,
    String? avatarUrl,
  }) = _OrderParty;
}

/// The outfit the order commissions (web `CommissionRequest.post` parity).
@freezed
abstract class OrderPostSummary with _$OrderPostSummary {
  const factory OrderPostSummary({
    required String id,
    required String caption,
    required String thumbUrl,
  }) = _OrderPostSummary;
}

/// Delivery address, frozen at submit (data-model.md §6.3).
@freezed
abstract class DeliveryAddress with _$DeliveryAddress {
  const factory DeliveryAddress({
    required String recipientName,
    required String phone,
    required String line1,
    required String city,
    required String state,
    required String country,
  }) = _DeliveryAddress;
}

/// One frozen measurement value inside a snapshot.
@freezed
abstract class SnapshotMeasurement with _$SnapshotMeasurement {
  const factory SnapshotMeasurement({
    required String name,
    required double valueCm,
  }) = _SnapshotMeasurement;
}

/// The measurement snapshot frozen at `requested` (order-lifecycle.md §1:
/// later vault changes never mutate an order).
@freezed
abstract class OrderSnapshot with _$OrderSnapshot {
  const factory OrderSnapshot({
    required String method,
    required DateTime measuredAt,
    required List<SnapshotMeasurement> measurements,
  }) = _OrderSnapshot;
}

/// One timeline event (web `OrderEvent` parity — MI-14 rows).
@freezed
abstract class OrderEvent with _$OrderEvent {
  const factory OrderEvent({
    required String kind,
    required String actor,
    required DateTime createdAt,
  }) = _OrderEvent;
}

/// The dispute record while an order is `disputed`.
@freezed
abstract class OrderDispute with _$OrderDispute {
  const factory OrderDispute({
    required DisputeReason reason,
    String? detail,
  }) = _OrderDispute;
}

/// Escrow state (order-lifecycle.md §3; web `Payment.state` parity).
enum PaymentState {
  held('held'),
  released('released'),
  refunded('refunded');

  const PaymentState(this.wireName);

  final String wireName;

  static PaymentState fromWireName(String name) =>
      values.firstWhere((state) => state.wireName == name);
}

/// The escrow record once a quote is paid (A-1: 10% platform fee).
@freezed
abstract class OrderPayment with _$OrderPayment {
  const factory OrderPayment({
    required PaymentState state,
    required int amountCents,
    required int platformFeeCents,
  }) = _OrderPayment;
}

/// A commission order (data-model.md §5 REQUEST; web `CommissionRequest`
/// parity — same order numbers/quotes/events as the web mock seed).
@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String orderNumber,
    required OrderPostSummary post,
    required OrderParty customer,
    required OrderParty designer,
    required OrderStatus status,
    required OrderSnapshot snapshot,
    required List<OrderEvent> events,
    required DateTime createdAt,

    /// The signed-in viewer's side (drives the C8 role tabs + actions).
    required OrderRole viewerRole,
    @Default('') String notes,
    int? budgetCents,
    int? quoteCents,
    @Default('NGN') String currency,
    DateTime? dueAt,
    String? tracking,
    DeclineReason? declineReason,

    /// The optional note the designer attached when declining (D04 —
    /// pages.md B3 "reason enum + optional note").
    String? declineNote,
    OrderDispute? dispute,
    DeliveryAddress? delivery,
    OrderPayment? payment,
  }) = _Order;

  const Order._();

  /// The headline amount a C8 row shows — quote once one exists, the
  /// customer's budget before that.
  int? get displayAmountCents => quoteCents ?? budgetCents;
}
