import 'dart:async';

import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// Abstract auth repository (mobile-implementation.md §6/§9) —
/// `AuthRepositoryFirebase` is the real Google-only flow,
/// `AuthRepositoryFake` serves dev and tests over the same interface.
///
/// Failures cross this boundary only as `AuthException` — SDK exception
/// types never leak above the repository.
abstract class AuthRepository {
  /// Silent session restore on app start (§9) — never shows UI. Returns
  /// the restored session, or null when signed out.
  Future<AuthSession?> restoreSession();

  /// The interactive "Continue with Google" flow (flows/auth.md §3).
  ///
  /// Throws `AuthException` on failure — including
  /// `AuthErrorCode.canceled` when the sheet is dismissed, which callers
  /// treat as a silent return (flows/auth.md §4).
  Future<AuthSession> signInWithGoogle();

  /// SDK sign-out + purge of locally persisted tokens (flows/auth.md §2).
  Future<void> signOut();

  /// Session transitions after the initial restore (sign-in/sign-out).
  Stream<AuthSession?> sessionChanges();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists;
/// dev runs the fake, prod swaps in Firebase once its options land
/// (mobile-implementation.md §6/§9).
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => throw UnimplementedError(
  'authRepository must be overridden with a *Fake or Firebase '
  'implementation (mobile-implementation.md §6)',
);

/// App-wide session state (§5/§9): the first value is the silent restore
/// (`attemptLightweightAuthentication` under Firebase), then the stream
/// follows the repository's session transitions. The router redirect and
/// its `refreshListenable` hang off this provider.
///
/// Changes are subscribed BEFORE the restore resolves: repository change
/// streams don't replay, so a sign-in racing the silent restore must not
/// be lost — the restore result only lands if no transition beat it.
@Riverpod(keepAlive: true)
Stream<AuthSession?> authSession(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  final controller = StreamController<AuthSession?>();
  var sawChange = false;
  final subscription = repository.sessionChanges().listen(
    (session) {
      sawChange = true;
      controller.add(session);
    },
    onError: controller.addError,
  );
  Future<void> restore() async {
    try {
      final session = await repository.restoreSession();
      if (!sawChange && !controller.isClosed) controller.add(session);
    } on Object catch (error, stackTrace) {
      if (!controller.isClosed) controller.addError(error, stackTrace);
    }
  }

  unawaited(restore());
  ref.onDispose(() {
    unawaited(subscription.cancel());
    unawaited(controller.close());
  });
  return controller.stream;
}
