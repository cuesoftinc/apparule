// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single configured Dio client (mobile-implementation.md §6) — the
/// data-layer shape is real from day one, but nothing calls it until the
/// API wave (§1 phase 4) introduces the `*Remote` repositories.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// The single configured Dio client (mobile-implementation.md §6) — the
/// data-layer shape is real from day one, but nothing calls it until the
/// API wave (§1 phase 4) introduces the `*Remote` repositories.

final class ApiClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// The single configured Dio client (mobile-implementation.md §6) — the
  /// data-layer shape is real from day one, but nothing calls it until the
  /// API wave (§1 phase 4) introduces the `*Remote` repositories.
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$apiClientHash() => r'be1340657a5daca3c25d15ce6b14867a1c2fb0c0';
