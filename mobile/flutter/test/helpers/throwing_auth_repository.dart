import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';

/// Test double for the failure paths (flows/auth.md §4): every
/// interactive sign-in throws [exception]; restore reads signed out.
class ThrowingAuthRepository implements AuthRepository {
  ThrowingAuthRepository(this.exception);

  final AuthException exception;

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> signInWithGoogle() async => throw exception;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthSession?> sessionChanges() => const Stream<AuthSession?>.empty();
}
