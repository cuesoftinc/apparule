// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payout_account_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(PayoutAccountViewModel)
final payoutAccountViewModelProvider = PayoutAccountViewModelProvider._();

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
final class PayoutAccountViewModelProvider
    extends $NotifierProvider<PayoutAccountViewModel, PayoutFormState> {
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
  PayoutAccountViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'payoutAccountViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$payoutAccountViewModelHash();

  @$internal
  @override
  PayoutAccountViewModel create() => PayoutAccountViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PayoutFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PayoutFormState>(value),
    );
  }
}

String _$payoutAccountViewModelHash() =>
    r'd012635faa99fb4f771fd6f7c673f1de5a155d09';

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

abstract class _$PayoutAccountViewModel extends $Notifier<PayoutFormState> {
  PayoutFormState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PayoutFormState, PayoutFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PayoutFormState, PayoutFormState>,
              PayoutFormState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
