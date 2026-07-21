// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persistence_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(persistenceService)
final persistenceServiceProvider = PersistenceServiceProvider._();

final class PersistenceServiceProvider
    extends
        $FunctionalProvider<
          PersistenceService,
          PersistenceService,
          PersistenceService
        >
    with $Provider<PersistenceService> {
  PersistenceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'persistenceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$persistenceServiceHash();

  @$internal
  @override
  $ProviderElement<PersistenceService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PersistenceService create(Ref ref) {
    return persistenceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersistenceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersistenceService>(value),
    );
  }
}

String _$persistenceServiceHash() =>
    r'07a9724086d6d9ab060cf2ac8b137c7584b5f131';
