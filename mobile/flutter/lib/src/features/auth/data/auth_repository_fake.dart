import 'dart:async';

import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';

/// TEST_MODE-parity fake (mobile-implementation.md §6/§9): instant
/// sign-in as the seeded §6 test user, so every screen downstream of
/// sign-in works identically over fakes before Firebase wiring lands.
class AuthRepositoryFake implements AuthRepository {
  /// [initialSession] seeds a signed-in state — `main_dev` boots signed in
  /// with [seedSession]; tests (and prod, until its Firebase swap) start
  /// signed out.
  AuthRepositoryFake({AuthSession? initialSession}) : _session = initialSession;

  /// The §6 signed-in test user — the same persona as the web mock seed
  /// (`kiki.adeyemi`), so the phone and the web dashboard tell one
  /// coherent demo story (web-implementation.md §6 parity).
  static const AuthSession seedSession = AuthSession(
    uid: 'test-uid-kiki',
    email: 'kiki.adeyemi@example.com',
    displayName: 'Kiki Adeyemi',
  );

  AuthSession? _session;
  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast();

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<AuthSession> signInWithGoogle() async {
    final session = _session ?? seedSession;
    _session = session;
    _changes.add(session);
    return session;
  }

  @override
  Future<void> signOut() async {
    _session = null;
    _changes.add(null);
  }

  @override
  Stream<AuthSession?> sessionChanges() => _changes.stream;
}
