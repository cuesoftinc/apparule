// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C14 placeholder ViewModel — watches the abstract earnings
/// repository; flavor overrides supply the fake.

@ProviderFor(EarningsViewModel)
final earningsViewModelProvider = EarningsViewModelProvider._();

/// C14 placeholder ViewModel — watches the abstract earnings
/// repository; flavor overrides supply the fake.
final class EarningsViewModelProvider
    extends $AsyncNotifierProvider<EarningsViewModel, List<Payout>> {
  /// C14 placeholder ViewModel — watches the abstract earnings
  /// repository; flavor overrides supply the fake.
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

String _$earningsViewModelHash() => r'cbd9a678e840e204bf578cdd25ae7476e5d97921';

/// C14 placeholder ViewModel — watches the abstract earnings
/// repository; flavor overrides supply the fake.

abstract class _$EarningsViewModel extends $AsyncNotifier<List<Payout>> {
  FutureOr<List<Payout>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Payout>>, List<Payout>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Payout>>, List<Payout>>,
              AsyncValue<List<Payout>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
