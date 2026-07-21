// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).

@ProviderFor(measurementRepository)
final measurementRepositoryProvider = MeasurementRepositoryProvider._();

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).

final class MeasurementRepositoryProvider
    extends
        $FunctionalProvider<
          MeasurementRepository,
          MeasurementRepository,
          MeasurementRepository
        >
    with $Provider<MeasurementRepository> {
  /// Overridden per entrypoint (di.dart) — no default implementation exists
  /// until the API wave lands `*Remote` (mobile-implementation.md §6).
  MeasurementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'measurementRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measurementRepositoryHash();

  @$internal
  @override
  $ProviderElement<MeasurementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeasurementRepository create(Ref ref) {
    return measurementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeasurementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeasurementRepository>(value),
    );
  }
}

String _$measurementRepositoryHash() =>
    r'a8e7fbf13cf05b12b880b43cf35f76bd505437f3';
