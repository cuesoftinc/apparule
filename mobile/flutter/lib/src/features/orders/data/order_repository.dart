import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_repository.g.dart';

/// Abstract order repository — C5/C8 (mobile-implementation.md §3).
abstract class OrderRepository {
  /// The signed-in user's orders, both roles (C8).
  Future<List<Order>> orders();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) => throw UnimplementedError(
  'orderRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
