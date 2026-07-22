// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The viewer's designer/KYC state — the C9 settings rows, the C8
/// KYC-lapse banner, and C14's status line all watch this one
/// derivation.

@ProviderFor(designerStatus)
final designerStatusProvider = DesignerStatusProvider._();

/// The viewer's designer/KYC state — the C9 settings rows, the C8
/// KYC-lapse banner, and C14's status line all watch this one
/// derivation.

final class DesignerStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<DesignerStatus>,
          DesignerStatus,
          FutureOr<DesignerStatus>
        >
    with $FutureModifier<DesignerStatus>, $FutureProvider<DesignerStatus> {
  /// The viewer's designer/KYC state — the C9 settings rows, the C8
  /// KYC-lapse banner, and C14's status line all watch this one
  /// derivation.
  DesignerStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'designerStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$designerStatusHash();

  @$internal
  @override
  $FutureProviderElement<DesignerStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DesignerStatus> create(Ref ref) {
    return designerStatus(ref);
  }
}

String _$designerStatusHash() => r'8a23536c6c5431b68828ae1100329e706e63baf3';

/// C14's ViewModel — the summary + ledger. Non-designers surface as the
/// repository's `designer_profile_required` error, which the screen maps
/// to the become-a-designer empty state (web `EarningsView` parity).

@ProviderFor(EarningsViewModel)
final earningsViewModelProvider = EarningsViewModelProvider._();

/// C14's ViewModel — the summary + ledger. Non-designers surface as the
/// repository's `designer_profile_required` error, which the screen maps
/// to the become-a-designer empty state (web `EarningsView` parity).
final class EarningsViewModelProvider
    extends $AsyncNotifierProvider<EarningsViewModel, Earnings> {
  /// C14's ViewModel — the summary + ledger. Non-designers surface as the
  /// repository's `designer_profile_required` error, which the screen maps
  /// to the become-a-designer empty state (web `EarningsView` parity).
  EarningsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'earningsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$earningsViewModelHash();

  @$internal
  @override
  EarningsViewModel create() => EarningsViewModel();
}

String _$earningsViewModelHash() => r'6cbe30b4a0d8e2f76c98fe537b8e2bc499bcf326';

/// C14's ViewModel — the summary + ledger. Non-designers surface as the
/// repository's `designer_profile_required` error, which the screen maps
/// to the become-a-designer empty state (web `EarningsView` parity).

abstract class _$EarningsViewModel extends $AsyncNotifier<Earnings> {
  FutureOr<Earnings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Earnings>, Earnings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Earnings>, Earnings>,
              AsyncValue<Earnings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
