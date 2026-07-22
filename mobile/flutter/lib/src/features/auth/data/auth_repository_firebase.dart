import 'dart:async';

import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The real §9 implementation — Google-only Firebase Auth on
/// `sandbox-e306a`, via the google_sign_in 7 rewrite:
///
///   `GoogleSignIn.instance.initialize(serverClientId)` →
///   `.authenticate()` → `GoogleAuthProvider.credential(idToken:)` →
///   `signInWithCredential`
///
/// Silent restore uses `attemptLightweightAuthentication()` (§9 —
/// replacing the legacy splash routing, audit critical finding #4).
/// Session tokens at rest go through [PersistenceService]'s secure
/// storage — never SharedPreferences (CV-2).
///
/// Requires `Firebase.initializeApp` with the flavor's options file
/// (`firebase_options.dart` / `firebase_options_dev.dart`) before use
/// (bootstrap's `firebaseOptions` seam).
class AuthRepositoryFirebase implements AuthRepository {
  AuthRepositoryFirebase({
    required this._firebaseAuth,
    required this._googleSignIn,
    required this._persistenceService,
    this.serverClientId,
  });

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final PersistenceService _persistenceService;

  /// The Firebase project's web/server OAuth client id — required on
  /// Android for ID-token minting; sourced from the flavor env config
  /// (`GOOGLE_SERVER_CLIENT_ID` dart-define) when Firebase options land.
  final String? serverClientId;

  Future<void>? _initialization;

  /// google_sign_in 7 contract: `initialize` is called exactly once, and
  /// its future completed, before any other method on the instance.
  Future<void> _ensureInitialized() =>
      _initialization ??= _googleSignIn.initialize(
        serverClientId: serverClientId,
      );

  @override
  Stream<AuthSession?> sessionChanges() => _firebaseAuth.authStateChanges().map(
    (user) => user == null ? null : _sessionOf(user),
  );

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      await _ensureInitialized();
      final current = _firebaseAuth.currentUser;
      if (current != null) return _sessionOf(current);
      // Silent restore — no UI; null when there is no prior session.
      final attempt = _googleSignIn.attemptLightweightAuthentication();
      if (attempt == null) {
        // Stream-only platforms (e.g. web FedCM): assume signed out and
        // let authStateChanges deliver any late sign-in.
        return null;
      }
      final account = await attempt;
      if (account == null) return null;
      return await _signInToFirebase(account);
    } on AuthException {
      // Restore is best-effort by contract: a failed silent attempt means
      // signed out, never a boot error.
      return null;
    } on GoogleSignInException {
      return null;
    }
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    await _ensureInitialized();
    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      throw AuthException(_mapGoogleCode(error.code), error.description);
    }
    return _signInToFirebase(account);
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    // SDK signOut + purge local caches (flows/auth.md §2).
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    await _persistenceService.clearSessionToken();
  }

  Future<AuthSession> _signInToFirebase(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException(
        AuthErrorCode.unknown,
        'Google authentication returned no ID token',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseCode(error.code), error.message);
    }
    final user = userCredential.user;
    if (user == null) {
      throw const AuthException(
        AuthErrorCode.unknown,
        'Firebase returned no user for the Google credential',
      );
    }
    // Token at rest through the persistence seam (§9): secure storage,
    // never SharedPreferences (CV-2). The SDK auto-refreshes (~1h).
    final sessionToken = await user.getIdToken();
    if (sessionToken != null) {
      await _persistenceService.writeSessionToken(sessionToken);
    }
    return _sessionOf(user);
  }

  AuthSession _sessionOf(User user) => AuthSession(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );

  /// flows/auth.md §4: dismissed sheet (and its interrupted/no-UI
  /// variants) → silent return; the rest surfaces as retryable unknown.
  static AuthErrorCode _mapGoogleCode(GoogleSignInExceptionCode code) =>
      switch (code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable => AuthErrorCode.canceled,
        _ => AuthErrorCode.unknown,
      };

  /// flows/auth.md §4: the two Firebase SDK constants the flow names.
  static AuthErrorCode _mapFirebaseCode(String code) => switch (code) {
    'network-request-failed' => AuthErrorCode.network,
    'user-disabled' => AuthErrorCode.userDisabled,
    _ => AuthErrorCode.unknown,
  };
}
