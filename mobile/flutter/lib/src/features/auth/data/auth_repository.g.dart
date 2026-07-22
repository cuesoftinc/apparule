// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden per entrypoint (di.dart) — no default implementation exists;
/// dev runs the fake, prod swaps in Firebase once its options land
/// (mobile-implementation.md §6/§9).

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Overridden per entrypoint (di.dart) — no default implementation exists;
/// dev runs the fake, prod swaps in Firebase once its options land
/// (mobile-implementation.md §6/§9).

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Overridden per entrypoint (di.dart) — no default implementation exists;
  /// dev runs the fake, prod swaps in Firebase once its options land
  /// (mobile-implementation.md §6/§9).
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'5a3aa3d69d17fbb401107b8d4970cc0ca6a16085';

/// App-wide session state (§5/§9): the first value is the silent restore
/// (`attemptLightweightAuthentication` under Firebase), then the stream
/// follows the repository's session transitions. The router redirect and
/// its `refreshListenable` hang off this provider.
///
/// Changes are subscribed BEFORE the restore resolves: repository change
/// streams don't replay, so a sign-in racing the silent restore must not
/// be lost — the restore result only lands if no transition beat it.

@ProviderFor(authSession)
final authSessionProvider = AuthSessionProvider._();

/// App-wide session state (§5/§9): the first value is the silent restore
/// (`attemptLightweightAuthentication` under Firebase), then the stream
/// follows the repository's session transitions. The router redirect and
/// its `refreshListenable` hang off this provider.
///
/// Changes are subscribed BEFORE the restore resolves: repository change
/// streams don't replay, so a sign-in racing the silent restore must not
/// be lost — the restore result only lands if no transition beat it.

final class AuthSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthSession?>,
          AuthSession?,
          Stream<AuthSession?>
        >
    with $FutureModifier<AuthSession?>, $StreamProvider<AuthSession?> {
  /// App-wide session state (§5/§9): the first value is the silent restore
  /// (`attemptLightweightAuthentication` under Firebase), then the stream
  /// follows the repository's session transitions. The router redirect and
  /// its `refreshListenable` hang off this provider.
  ///
  /// Changes are subscribed BEFORE the restore resolves: repository change
  /// streams don't replay, so a sign-in racing the silent restore must not
  /// be lost — the restore result only lands if no transition beat it.
  AuthSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionHash();

  @$internal
  @override
  $StreamProviderElement<AuthSession?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AuthSession?> create(Ref ref) {
    return authSession(ref);
  }
}

String _$authSessionHash() => r'1b0c65a276b696fde4b7cf35e0e66e854a476bf6';
