// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_entry_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The profile's A-10 template — null interposes the one-time chooser on
/// the manual entry screen. Auto-disposes with the route, so a Settings
/// edit is picked up on the next visit.

@ProviderFor(manualTemplate)
final manualTemplateProvider = ManualTemplateProvider._();

/// The profile's A-10 template — null interposes the one-time chooser on
/// the manual entry screen. Auto-disposes with the route, so a Settings
/// edit is picked up on the next visit.

final class ManualTemplateProvider
    extends
        $FunctionalProvider<
          AsyncValue<MeasurementTemplate?>,
          MeasurementTemplate?,
          FutureOr<MeasurementTemplate?>
        >
    with
        $FutureModifier<MeasurementTemplate?>,
        $FutureProvider<MeasurementTemplate?> {
  /// The profile's A-10 template — null interposes the one-time chooser on
  /// the manual entry screen. Auto-disposes with the route, so a Settings
  /// edit is picked up on the next visit.
  ManualTemplateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualTemplateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualTemplateHash();

  @$internal
  @override
  $FutureProviderElement<MeasurementTemplate?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MeasurementTemplate?> create(Ref ref) {
    return manualTemplate(ref);
  }
}

String _$manualTemplateHash() => r'1de43c3ab69b17cee76c03a7ddd8f58369f543bf';

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
    r'0c2e6af64ce092e13c4fd050e028006f9adf352a';

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
