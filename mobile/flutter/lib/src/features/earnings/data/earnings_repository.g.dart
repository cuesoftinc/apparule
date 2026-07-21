// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).

@ProviderFor(earningsRepository)
final earningsRepositoryProvider = EarningsRepositoryProvider._();

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).

final class EarningsRepositoryProvider
    extends
        $FunctionalProvider<
          EarningsRepository,
          EarningsRepository,
          EarningsRepository
        >
    with $Provider<EarningsRepository> {
  /// Overridden per entrypoint (di.dart) — no default implementation exists
  /// until the API wave lands `*Remote` (mobile-implementation.md §6).
  EarningsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'earningsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$earningsRepositoryHash();

  @$internal
  @override
  $ProviderElement<EarningsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EarningsRepository create(Ref ref) {
    return earningsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EarningsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EarningsRepository>(value),
    );
  }
}

String _$earningsRepositoryHash() =>
    r'fe006ab2b8ecf120f283f4783b3847c0ab00e3a2';
