import 'package:freezed_annotation/freezed_annotation.dart';

part 'earnings.freezed.dart';

/// C14 ledger row kinds (design.md §8.2b earnings rows; web
/// `EarningsEntry.kind`).
enum EarningsEntryKind { payout, escrowHeld, feeLine }

/// One C14 ledger line — payouts read negative (money leaving the
/// released balance for the bank), escrow holds carry the order's gross
/// amount while `held` (the ratified C14 canvas semantics, 267:8613).
@freezed
abstract class EarningsEntry with _$EarningsEntry {
  const factory EarningsEntry({
    required String id,
    required EarningsEntryKind kind,
    required int amountCents,
    required DateTime createdAt,
    @Default('NGN') String currency,
    String? label,
    String? orderNumber,
    String? providerRef,
    @Default(false) bool held,
  }) = _EarningsEntry;
}

/// The C14 summary + ledger (web `Earnings` parity): available is the
/// released balance, pending the escrow still held on open orders — it
/// releases when delivery is confirmed.
@freezed
abstract class Earnings with _$Earnings {
  const factory Earnings({
    required int availableCents,
    required int pendingCents,
    @Default('NGN') String currency,
    @Default(<EarningsEntry>[]) List<EarningsEntry> transactions,
  }) = _Earnings;
}
