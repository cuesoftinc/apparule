import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orders_view_model.g.dart';

/// C8 placeholder ViewModel — watches the abstract order repository;
/// flavor overrides supply the fake.
@riverpod
class OrdersViewModel extends _$OrdersViewModel {
  @override
  Future<List<Order>> build() => ref.watch(orderRepositoryProvider).orders();
}
