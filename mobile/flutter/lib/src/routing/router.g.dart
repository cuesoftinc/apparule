// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app router (mobile-implementation.md §5): typed routes, a
/// StatefulShellRoute tab shell, and one top-level auth redirect.
///
/// The redirect is STUBBED to always-allow this wave — the auth wave binds
/// it to the session provider (via `refreshListenable`) so every route
/// except `/signin` gates behind sign-in, replacing the legacy push-only
/// Navigator 1.0 chains (CV-7).

@ProviderFor(router)
final routerProvider = RouterProvider._();

/// The app router (mobile-implementation.md §5): typed routes, a
/// StatefulShellRoute tab shell, and one top-level auth redirect.
///
/// The redirect is STUBBED to always-allow this wave — the auth wave binds
/// it to the session provider (via `refreshListenable`) so every route
/// except `/signin` gates behind sign-in, replacing the legacy push-only
/// Navigator 1.0 chains (CV-7).

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app router (mobile-implementation.md §5): typed routes, a
  /// StatefulShellRoute tab shell, and one top-level auth redirect.
  ///
  /// The redirect is STUBBED to always-allow this wave — the auth wave binds
  /// it to the session provider (via `refreshListenable`) so every route
  /// except `/signin` gates behind sign-in, replacing the legacy push-only
  /// Navigator 1.0 chains (CV-7).
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'bc64e2574112e4bf6485af925cde5ac7bbbd24bd';
