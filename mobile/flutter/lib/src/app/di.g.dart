// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'di.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// DI = provider overrides per environment (mobile-implementation.md §4):
/// Riverpod's provider graph is the only injection mechanism — no second
/// container. Each entrypoint builds a ProviderScope from these sets.
///
/// The current flavor, overridden by [appFlavorProvider]'s entrypoint
/// override in bootstrap.

@ProviderFor(appFlavor)
final appFlavorProvider = AppFlavorProvider._();

/// DI = provider overrides per environment (mobile-implementation.md §4):
/// Riverpod's provider graph is the only injection mechanism — no second
/// container. Each entrypoint builds a ProviderScope from these sets.
///
/// The current flavor, overridden by [appFlavorProvider]'s entrypoint
/// override in bootstrap.

final class AppFlavorProvider
    extends $FunctionalProvider<AppFlavor, AppFlavor, AppFlavor>
    with $Provider<AppFlavor> {
  /// DI = provider overrides per environment (mobile-implementation.md §4):
  /// Riverpod's provider graph is the only injection mechanism — no second
  /// container. Each entrypoint builds a ProviderScope from these sets.
  ///
  /// The current flavor, overridden by [appFlavorProvider]'s entrypoint
  /// override in bootstrap.
  AppFlavorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appFlavorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appFlavorHash();

  @$internal
  @override
  $ProviderElement<AppFlavor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppFlavor create(Ref ref) {
    return appFlavor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppFlavor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppFlavor>(value),
    );
  }
}

String _$appFlavorHash() => r'efba113cf79c7fa3a4227c545bac8941e3df4aa8';
