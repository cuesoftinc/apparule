// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C7 placeholder ViewModel — watches the abstract measurement
/// repository; flavor overrides supply the fake.

@ProviderFor(VaultViewModel)
final vaultViewModelProvider = VaultViewModelProvider._();

/// C7 placeholder ViewModel — watches the abstract measurement
/// repository; flavor overrides supply the fake.
final class VaultViewModelProvider
    extends $AsyncNotifierProvider<VaultViewModel, List<MeasurementSession>> {
  /// C7 placeholder ViewModel — watches the abstract measurement
  /// repository; flavor overrides supply the fake.
  VaultViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vaultViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vaultViewModelHash();

  @$internal
  @override
  VaultViewModel create() => VaultViewModel();
}

String _$vaultViewModelHash() => r'421bc085c70f775d30271a22866ca43970613266';

/// C7 placeholder ViewModel — watches the abstract measurement
/// repository; flavor overrides supply the fake.

abstract class _$VaultViewModel
    extends $AsyncNotifier<List<MeasurementSession>> {
  FutureOr<List<MeasurementSession>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<MeasurementSession>>,
              List<MeasurementSession>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MeasurementSession>>,
                List<MeasurementSession>
              >,
              AsyncValue<List<MeasurementSession>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
