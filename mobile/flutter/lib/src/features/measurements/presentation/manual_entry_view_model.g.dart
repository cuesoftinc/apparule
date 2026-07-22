// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_entry_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// MI-13 manual entry (1:1 with `ManualEntryScreen`) — the C6 fallback
/// path for QC that never clears or a denied camera; saves a
/// `method: manual` session (confidence null, capture-qc.md §4).

@ProviderFor(ManualEntryViewModel)
final manualEntryViewModelProvider = ManualEntryViewModelProvider._();

/// MI-13 manual entry (1:1 with `ManualEntryScreen`) — the C6 fallback
/// path for QC that never clears or a denied camera; saves a
/// `method: manual` session (confidence null, capture-qc.md §4).
final class ManualEntryViewModelProvider
    extends $NotifierProvider<ManualEntryViewModel, ManualEntryState> {
  /// MI-13 manual entry (1:1 with `ManualEntryScreen`) — the C6 fallback
  /// path for QC that never clears or a denied camera; saves a
  /// `method: manual` session (confidence null, capture-qc.md §4).
  ManualEntryViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualEntryViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualEntryViewModelHash();

  @$internal
  @override
  ManualEntryViewModel create() => ManualEntryViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualEntryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualEntryState>(value),
    );
  }
}

String _$manualEntryViewModelHash() =>
    r'9f5fa84ff7ebf40f66c9ed57a1452e36a46839ff';

/// MI-13 manual entry (1:1 with `ManualEntryScreen`) — the C6 fallback
/// path for QC that never clears or a denied camera; saves a
/// `method: manual` session (confidence null, capture-qc.md §4).

abstract class _$ManualEntryViewModel extends $Notifier<ManualEntryState> {
  ManualEntryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ManualEntryState, ManualEntryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ManualEntryState, ManualEntryState>,
              ManualEntryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
