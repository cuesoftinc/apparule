import 'dart:async';

import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';

/// TEST_MODE-parity fake (mobile-implementation.md §6/§9): instant
/// sign-in as the seeded §6 test user, so every screen downstream of
/// sign-in works identically over fakes before Firebase wiring lands.
///
/// The fake exercises the REAL session lifecycle (boot-flow directive
/// 2026-07-22): given a [PersistenceService] it persists a session marker
/// through the same secure-storage seam the Firebase implementation uses
/// for tokens at rest (§9, CV-2) — a sign-in survives relaunch, restore
/// finds it, and sign-out purges it, exactly like web's TEST_MODE
/// session. Without one (unit tests, seeded scenarios) it stays
/// in-memory.
class AuthRepositoryFake implements AuthRepository {
  /// [initialSession] seeds a signed-in state for tests without touching
  /// persistence; [persistenceService] opts into the persisted lifecycle
  /// (the entrypoints' default via `fakeRepositoryOverrides`).
  AuthRepositoryFake({
    AuthSession? initialSession,
    PersistenceService? persistenceService,
  }) : _session = initialSession,
       _persistence = persistenceService;

  /// The §6 signed-in test user — the same persona as the web mock seed
  /// (`kiki.adeyemi`), so the phone and the web dashboard tell one
  /// coherent demo story (web-implementation.md §6 parity).
  static const AuthSession seedSession = AuthSession(
    uid: 'test-uid-kiki',
    email: 'kiki.adeyemi@example.com',
    displayName: 'Kiki Adeyemi',
  );

  /// The marker written where the real flow keeps its ID token — clearly
  /// labeled so a captured device/keychain dump can never be mistaken
  /// for a real credential.
  static const String fakeSessionToken = 'fake-session:kiki.adeyemi';

  final PersistenceService? _persistence;
  AuthSession? _session;
  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast();

  @override
  Future<AuthSession?> restoreSession() async {
    if (_session != null) return _session;
    final persistence = _persistence;
    if (persistence == null) return null;
    // Silent restore parity (§9): a persisted marker is a prior sign-in.
    final token = await persistence.readSessionToken();
    if (token == null) return null;
    return _session = seedSession;
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    final session = _session ?? seedSession;
    _session = session;
    await _persistence?.writeSessionToken(fakeSessionToken);
    _changes.add(session);
    return session;
  }

  @override
  Future<void> signOut() async {
    _session = null;
    // Purge the persisted marker (flows/auth.md §2 parity) — the next
    // cold start restores nothing and boots to C1.
    await _persistence?.clearSessionToken();
    _changes.add(null);
  }

  @override
  Stream<AuthSession?> sessionChanges() => _changes.stream;
}
