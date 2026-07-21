import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';

/// Minimal placeholder domain model — the screens wave grows it to the
/// ten-state order lifecycle (mobile-implementation.md §6 orders seed).
@freezed
abstract class Order with _$Order {
  const factory Order({required String id}) = _Order;
}
