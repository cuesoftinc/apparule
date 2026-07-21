import 'package:freezed_annotation/freezed_annotation.dart';

part 'payout.freezed.dart';

/// Minimal placeholder domain model — the screens wave grows it to the
/// B9-parity transaction shape (mobile-implementation.md §3).
@freezed
abstract class Payout with _$Payout {
  const factory Payout({required String id}) = _Payout;
}
