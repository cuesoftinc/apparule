// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single configured Dio client (mobile-implementation.md §6) — the
/// auth repository and the `*Remote` repositories share it.
///
/// `API_URL` is the origin serving `/api/v1`, injected through
/// `--dart-define-from-file=env/<flavor>.json` (§2). Every request carries
/// `Authorization: Bearer <token>` while a session token is at rest.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// The single configured Dio client (mobile-implementation.md §6) — the
/// auth repository and the `*Remote` repositories share it.
///
/// `API_URL` is the origin serving `/api/v1`, injected through
/// `--dart-define-from-file=env/<flavor>.json` (§2). Every request carries
/// `Authorization: Bearer <token>` while a session token is at rest.

final class ApiClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// The single configured Dio client (mobile-implementation.md §6) — the
  /// auth repository and the `*Remote` repositories share it.
  ///
  /// `API_URL` is the origin serving `/api/v1`, injected through
  /// `--dart-define-from-file=env/<flavor>.json` (§2). Every request carries
  /// `Authorization: Bearer <token>` while a session token is at rest.
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

String _$apiClientHash() => r'c377a6c2c777c22ad25c8851eb01c1f7b18215e3';
