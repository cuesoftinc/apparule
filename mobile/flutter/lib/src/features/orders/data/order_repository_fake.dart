import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/domain/order.dart';

/// Empty-state fake — the seeded §6 narrative (assets/seed/) arrives with
/// the screens wave; the interface seam is what this wave establishes.
class OrderRepositoryFake implements OrderRepository {
  @override
  Future<List<Order>> orders() async => const <Order>[];
}
