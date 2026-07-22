import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orders_view_model.g.dart';

/// C8's list ViewModel — the viewer's orders, both roles, newest
/// activity first (the fake orders by last event).
@riverpod
class OrdersViewModel extends _$OrdersViewModel {
  @override
  Future<List<Order>> build() => ref.watch(orderRepositoryProvider).orders();

  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
  }
}
