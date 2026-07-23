import 'dart:async';

import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/domain/earnings_exception.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_view_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payout_account_view_model.freezed.dart';
part 'payout_account_view_model.g.dart';

/// The C13 payout-form phase — the four canvas frames: the idle form,
/// "Checking with your bank…", the resolved name confirm, and the failed
/// state with retry (+ support link, pages.md B8's after-3-fails rule).
enum PayoutFormPhase { idle, resolving, resolved, failed }

/// C13 banking-form state (Paystack resolution states, pages.md B8).
@freezed
abstract class PayoutFormState with _$PayoutFormState {
  const factory PayoutFormState({
    @Default(<BankOption>[]) List<BankOption> banks,
    BankOption? bank,
    @Default('') String accountNumber,
    @Default(PayoutFormPhase.idle) PayoutFormPhase phase,
    BankResolution? resolution,
    @Default(0) int failCount,
    @Default(false) bool saving,
  }) = _PayoutFormState;
}

/// C13 payout form — resolve on a complete (bank, 10-digit) pair;
/// save attaches the resolved account and re-derives the status
/// surfaces (C8 banner, C14 chip, settings row).
///
/// In-flight semantics (CLASS 8, D03): edits SUPERSEDE — every input
/// change while a resolve is in flight starts a fresh resolve owning a
/// new token, and a completed resolve whose token is stale is simply
/// dropped (the newer one owns the state). `resolving` therefore always
/// terminates in resolved/failed/idle; the phase can never wedge with
/// the spinner up and no Save or Retry in reach.
@riverpod
class PayoutAccountViewModel extends _$PayoutAccountViewModel {
  /// The supersede token — bumped by every resolve start AND every
  /// incomplete-input reset, so an in-flight result can always tell it
  /// has been overtaken.
  int _resolveToken = 0;

  @override
  PayoutFormState build() {
    unawaited(_loadBanks());
    return const PayoutFormState();
  }

  Future<void> _loadBanks() async {
    final banks = await ref.read(earningsRepositoryProvider).banks();
    state = state.copyWith(banks: banks);
  }

  void setBank(BankOption bank) {
    state = state.copyWith(bank: bank);
    unawaited(_maybeResolve());
  }

  void setAccountNumber(String value) {
    state = state.copyWith(accountNumber: value);
    unawaited(_maybeResolve());
  }

  /// The failed state's "Retry verification".
  Future<void> retry() => _maybeResolve();

  Future<void> _maybeResolve() async {
    final bank = state.bank;
    if (bank == null || state.accountNumber.length != 10) {
      // Incomplete pair: invalidate any in-flight resolve and rest idle.
      _resolveToken++;
      if (state.phase != PayoutFormPhase.idle) {
        state = state.copyWith(
          phase: PayoutFormPhase.idle,
          resolution: null,
        );
      }
      return;
    }
    final token = ++_resolveToken;
    state = state.copyWith(
      phase: PayoutFormPhase.resolving,
      resolution: null,
    );
    try {
      final resolution = await ref
          .read(earningsRepositoryProvider)
          .resolveBank(bank.code, state.accountNumber);
      // Superseded mid-flight — the newer resolve owns the state.
      if (token != _resolveToken) return;
      state = state.copyWith(
        phase: PayoutFormPhase.resolved,
        resolution: resolution,
      );
    } on EarningsException {
      if (token != _resolveToken) return;
      state = state.copyWith(
        phase: PayoutFormPhase.failed,
        failCount: state.failCount + 1,
      );
    }
  }

  /// Attaches the resolved account; true on success.
  Future<bool> save() async {
    final bank = state.bank;
    if (bank == null || state.phase != PayoutFormPhase.resolved) return false;
    state = state.copyWith(saving: true);
    try {
      await ref
          .read(earningsRepositoryProvider)
          .attachPayoutAccount(bank.code, state.accountNumber);
      ref
        ..invalidate(designerStatusProvider)
        ..invalidate(earningsViewModelProvider);
      return true;
    } on EarningsException {
      state = state.copyWith(
        phase: PayoutFormPhase.failed,
        failCount: state.failCount + 1,
      );
      return false;
    } finally {
      state = state.copyWith(saving: false);
    }
  }
}
