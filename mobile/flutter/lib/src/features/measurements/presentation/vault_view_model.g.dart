// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C7's ViewModel — the saved sessions, newest first (the capture and
/// manual-entry flows invalidate this after a save so the vault lists
/// the new session on arrival).

@ProviderFor(VaultViewModel)
final vaultViewModelProvider = VaultViewModelProvider._();

/// C7's ViewModel — the saved sessions, newest first (the capture and
/// manual-entry flows invalidate this after a save so the vault lists
/// the new session on arrival).
final class VaultViewModelProvider
    extends $AsyncNotifierProvider<VaultViewModel, List<MeasurementSession>> {
  /// C7's ViewModel — the saved sessions, newest first (the capture and
  /// manual-entry flows invalidate this after a save so the vault lists
  /// the new session on arrival).
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

String _$vaultViewModelHash() => r'dc855ab90f2522124706bc10cf82ae07dda037dc';

/// C7's ViewModel — the saved sessions, newest first (the capture and
/// manual-entry flows invalidate this after a save so the vault lists
/// the new session on arrival).

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
