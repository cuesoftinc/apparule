// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_sample_catalog.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Catalog for the capture screen's dev-flavor QC selector (the fake
/// repository loads its own copy lazily).

@ProviderFor(captureSampleCatalog)
final captureSampleCatalogProvider = CaptureSampleCatalogProvider._();

/// Catalog for the capture screen's dev-flavor QC selector (the fake
/// repository loads its own copy lazily).

final class CaptureSampleCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<CaptureSampleCatalog>,
          CaptureSampleCatalog,
          FutureOr<CaptureSampleCatalog>
        >
    with
        $FutureModifier<CaptureSampleCatalog>,
        $FutureProvider<CaptureSampleCatalog> {
  /// Catalog for the capture screen's dev-flavor QC selector (the fake
  /// repository loads its own copy lazily).
  CaptureSampleCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureSampleCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureSampleCatalogHash();

  @$internal
  @override
  $FutureProviderElement<CaptureSampleCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CaptureSampleCatalog> create(Ref ref) {
    return captureSampleCatalog(ref);
  }
}

String _$captureSampleCatalogHash() =>
    r'e08a0319caf5b94c086908aeb9360d7702172f18';
