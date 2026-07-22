import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/domain/thread_message.dart';
import 'package:apparule/src/features/orders/presentation/orders_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_detail_view_model.g.dart';

/// What C8's detail renders: the order plus its thread.
typedef OrderDetailState = ({Order order, List<ThreadMessage> messages});

/// C8's detail ViewModel — every action is a REAL lifecycle transition on
/// the repository (validated against order-lifecycle.md §1); the updated
/// order echoes into this state and invalidates the list so its pill
/// pulses to the new state (MI-14).
@riverpod
class OrderDetailViewModel extends _$OrderDetailViewModel {
  @override
  Future<OrderDetailState> build(String orderId) async {
    final repository = ref.watch(orderRepositoryProvider);
    return (
      order: await repository.order(orderId),
      messages: await repository.messages(orderId),
    );
  }

  OrderRepository get _repository => ref.read(orderRepositoryProvider);

  Future<void> pay() => _apply(() => _repository.pay(orderId));

  Future<void> confirmDelivery() =>
      _apply(() => _repository.confirmDelivery(orderId));

  Future<void> withdraw() => _apply(() => _repository.cancel(orderId));

  Future<void> openDispute(DisputeReason reason, {String? detail}) => _apply(
    () => _repository.openDispute(orderId, reason, detail: detail),
  );

  Future<void> decline(DeclineReason reason) =>
      _apply(() => _repository.decline(orderId, reason));

  Future<void> sendQuote(int quoteCents, {required DateTime dueAt}) =>
      _apply(() => _repository.quote(orderId, quoteCents, dueAt: dueAt));

  Future<void> startProgress() =>
      _apply(() => _repository.startProgress(orderId));

  Future<void> ship({String? tracking}) =>
      _apply(() => _repository.ship(orderId, tracking: tracking));

  Future<void> sendMessage(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _repository.sendMessage(orderId, trimmed);
    // Re-read: the scripted counterparty reply may have landed (MI-17).
    final messages = await _repository.messages(orderId);
    if (state.value case final current?) {
      state = AsyncData((order: current.order, messages: messages));
    }
  }

  Future<void> _apply(Future<Order> Function() action) async {
    final updated = await action();
    if (state.value case final current?) {
      state = AsyncData((order: updated, messages: current.messages));
    }
    ref.invalidate(ordersViewModelProvider);
  }
}
