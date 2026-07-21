import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// Abstract auth repository (mobile-implementation.md §6/§9) —
/// `AuthRepositoryFirebase` arrives at the auth cutover;
/// `AuthRepositoryFake` serves dev/stg.
abstract class AuthRepository {
  /// The restored session, or null when signed out.
  Future<AuthSession?> restoreSession();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => throw UnimplementedError(
  'authRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
