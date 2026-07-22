import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/features/auth/data/auth_repository_firebase.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

// The §9 flow tested at the repository seam with mocked SDK classes —
// pure Dart, no platform channels (mobile-implementation.md §8; the
// fake covers the contract, this covers the google_sign_in 7 →
// Firebase call sequence and the flows/auth.md §4 error mapping).

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _MockPersistenceService extends Mock implements PersistenceService {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late _MockGoogleSignIn googleSignIn;
  late _MockPersistenceService persistenceService;
  late AuthRepositoryFirebase repository;

  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
  });

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    googleSignIn = _MockGoogleSignIn();
    persistenceService = _MockPersistenceService();
    repository = AuthRepositoryFirebase(
      firebaseAuth: firebaseAuth,
      googleSignIn: googleSignIn,
      persistenceService: persistenceService,
      serverClientId: 'server-client-id',
    );
    when(
      () => googleSignIn.initialize(
        serverClientId: any(named: 'serverClientId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => persistenceService.writeSessionToken(any()),
    ).thenAnswer((_) async {});
    when(() => persistenceService.clearSessionToken()).thenAnswer((_) async {});
  });

  _MockUser stubUser() {
    final user = _MockUser();
    when(() => user.uid).thenReturn('firebase-uid');
    when(() => user.email).thenReturn('kiki.adeyemi@example.com');
    when(() => user.displayName).thenReturn('Kiki Adeyemi');
    when(() => user.photoURL).thenReturn(null);
    when(user.getIdToken).thenAnswer((_) async => 'firebase-token');
    return user;
  }

  _MockGoogleSignInAccount stubAccount({String? idToken = 'google-token'}) {
    final account = _MockGoogleSignInAccount();
    when(
      () => account.authentication,
    ).thenReturn(GoogleSignInAuthentication(idToken: idToken));
    return account;
  }

  void stubFirebaseSignIn(User user) {
    final userCredential = _MockUserCredential();
    when(() => userCredential.user).thenReturn(user);
    when(
      () => firebaseAuth.signInWithCredential(any()),
    ).thenAnswer((_) async => userCredential);
  }

  group('signInWithGoogle', () {
    test(
      'runs the §9 sequence: initialize(serverClientId) → authenticate() '
      '→ credential(idToken) → signInWithCredential, persisting the token',
      () async {
        final account = stubAccount();
        when(
          () => googleSignIn.authenticate(),
        ).thenAnswer((_) async => account);
        stubFirebaseSignIn(stubUser());

        final session = await repository.signInWithGoogle();

        expect(
          session,
          const AuthSession(
            uid: 'firebase-uid',
            email: 'kiki.adeyemi@example.com',
            displayName: 'Kiki Adeyemi',
          ),
        );
        verify(
          () => googleSignIn.initialize(serverClientId: 'server-client-id'),
        ).called(1);
        final credential =
            verify(
                  () => firebaseAuth.signInWithCredential(captureAny()),
                ).captured.single
                as OAuthCredential;
        expect(credential.idToken, 'google-token');
        expect(credential.providerId, GoogleAuthProvider.PROVIDER_ID);
        // Token at rest through the secure-storage seam (§9, CV-2).
        verify(
          () => persistenceService.writeSessionToken('firebase-token'),
        ).called(1);
      },
    );

    test('initialize runs exactly once across calls (SDK contract)', () async {
      final account = stubAccount();
      when(
        () => googleSignIn.authenticate(),
      ).thenAnswer((_) async => account);
      stubFirebaseSignIn(stubUser());

      await repository.signInWithGoogle();
      await repository.signInWithGoogle();

      verify(
        () => googleSignIn.initialize(
          serverClientId: any(named: 'serverClientId'),
        ),
      ).called(1);
    });

    test('dismissed sheet maps to AuthErrorCode.canceled (flows §4)', () async {
      when(() => googleSignIn.authenticate()).thenThrow(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.canceled,
          ),
        ),
      );
    });

    test(
      'network-request-failed maps to AuthErrorCode.network (flows §4)',
      () async {
        when(
          () => googleSignIn.authenticate(),
        ).thenAnswer((_) async => stubAccount());
        when(
          () => firebaseAuth.signInWithCredential(any()),
        ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        await expectLater(
          repository.signInWithGoogle(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.network,
            ),
          ),
        );
      },
    );

    test(
      'user-disabled maps to AuthErrorCode.userDisabled (flows §4)',
      () async {
        when(
          () => googleSignIn.authenticate(),
        ).thenAnswer((_) async => stubAccount());
        when(
          () => firebaseAuth.signInWithCredential(any()),
        ).thenThrow(FirebaseAuthException(code: 'user-disabled'));

        await expectLater(
          repository.signInWithGoogle(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.userDisabled,
            ),
          ),
        );
      },
    );

    test(
      'a missing Google ID token surfaces as unknown, never a crash',
      () async {
        when(
          () => googleSignIn.authenticate(),
        ).thenAnswer((_) async => stubAccount(idToken: null));

        await expectLater(
          repository.signInWithGoogle(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.unknown,
            ),
          ),
        );
        verifyNever(() => firebaseAuth.signInWithCredential(any()));
      },
    );
  });

  group('restoreSession', () {
    test(
      'returns the current Firebase user without any Google round-trip',
      () async {
        final user = stubUser();
        when(() => firebaseAuth.currentUser).thenReturn(user);

        final session = await repository.restoreSession();

        expect(session?.uid, 'firebase-uid');
        verifyNever(() => googleSignIn.attemptLightweightAuthentication());
      },
    );

    test(
      'attempts lightweight authentication when signed out of Firebase',
      () async {
        final account = stubAccount();
        when(() => firebaseAuth.currentUser).thenReturn(null);
        when(() => googleSignIn.attemptLightweightAuthentication()).thenAnswer(
          (_) => Future<GoogleSignInAccount?>.value(account),
        );
        stubFirebaseSignIn(stubUser());

        final session = await repository.restoreSession();

        expect(session?.uid, 'firebase-uid');
        verify(
          () => persistenceService.writeSessionToken('firebase-token'),
        ).called(1);
      },
    );

    test('resolves signed out when there is nothing to restore', () async {
      when(() => firebaseAuth.currentUser).thenReturn(null);
      when(
        () => googleSignIn.attemptLightweightAuthentication(),
      ).thenAnswer((_) => Future<GoogleSignInAccount?>.value());

      expect(await repository.restoreSession(), isNull);
    });

    test(
      'is best-effort: a failing silent attempt reads as signed out',
      () async {
        final account = stubAccount();
        when(() => firebaseAuth.currentUser).thenReturn(null);
        when(() => googleSignIn.attemptLightweightAuthentication()).thenAnswer(
          (_) => Future<GoogleSignInAccount?>.value(account),
        );
        when(
          () => firebaseAuth.signInWithCredential(any()),
        ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        expect(await repository.restoreSession(), isNull);
      },
    );
  });

  group('signOut', () {
    test(
      'signs out both SDKs and purges the stored token (flows §2)',
      () async {
        when(() => googleSignIn.signOut()).thenAnswer((_) async {});
        when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

        await repository.signOut();

        verify(() => googleSignIn.signOut()).called(1);
        verify(() => firebaseAuth.signOut()).called(1);
        verify(() => persistenceService.clearSessionToken()).called(1);
      },
    );
  });

  group('sessionChanges', () {
    test('maps authStateChanges into nullable sessions', () async {
      final user = stubUser();
      when(() => firebaseAuth.authStateChanges()).thenAnswer(
        (_) => Stream<User?>.fromIterable(<User?>[null, user]),
      );

      final sessions = await repository.sessionChanges().toList();

      expect(sessions, hasLength(2));
      expect(sessions.first, isNull);
      expect(sessions.last?.uid, 'firebase-uid');
    });
  });
}
