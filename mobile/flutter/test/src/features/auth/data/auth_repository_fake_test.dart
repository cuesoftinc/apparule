import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_persistence.dart';

void main() {
  group('AuthRepositoryFake (repository contract)', () {
    test(
      'restoreSession is null when unseeded, the session when seeded',
      () async {
        expect(await AuthRepositoryFake().restoreSession(), isNull);
        expect(
          await AuthRepositoryFake(
            initialSession: AuthRepositoryFake.seedSession,
          ).restoreSession(),
          AuthRepositoryFake.seedSession,
        );
      },
    );

    test(
      'signInWithGoogle is instant, returns the §6 test user and emits it',
      () async {
        final repository = AuthRepositoryFake();
        final emissions = <AuthSession?>[];
        final subscription = repository.sessionChanges().listen(emissions.add);
        addTearDown(subscription.cancel);

        final session = await repository.signInWithGoogle();

        expect(session, AuthRepositoryFake.seedSession);
        expect(session.uid, 'test-uid-kiki');
        expect(await repository.restoreSession(), session);
        await pumpEventQueue();
        expect(emissions, <AuthSession?>[session]);
      },
    );

    test('signOut clears the session and emits null', () async {
      final repository = AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      );
      final emissions = <AuthSession?>[];
      final subscription = repository.sessionChanges().listen(emissions.add);
      addTearDown(subscription.cancel);

      await repository.signOut();

      expect(await repository.restoreSession(), isNull);
      await pumpEventQueue();
      expect(emissions, <AuthSession?>[null]);
    });

    test('sign-in after sign-out lands the seeded persona again', () async {
      final repository = AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      );
      await repository.signOut();
      expect(
        await repository.signInWithGoogle(),
        AuthRepositoryFake.seedSession,
      );
    });
  });

  group('AuthRepositoryFake (persisted lifecycle, boot-flow directive '
      '2026-07-22)', () {
    test('sign-in writes the session marker through the persistence '
        'seam', () async {
      final persistence = InMemoryPersistenceService();
      final repository = AuthRepositoryFake(persistenceService: persistence);

      await repository.signInWithGoogle();

      expect(persistence.sessionToken, AuthRepositoryFake.fakeSessionToken);
    });

    test('restore finds a persisted marker — a "relaunched" instance is '
        'signed in', () async {
      final persistence = InMemoryPersistenceService()
        ..sessionToken = AuthRepositoryFake.fakeSessionToken;
      final relaunched = AuthRepositoryFake(persistenceService: persistence);

      expect(
        await relaunched.restoreSession(),
        AuthRepositoryFake.seedSession,
      );
    });

    test('restore is null over empty persistence — first-ever launch is '
        'signed out', () async {
      final repository = AuthRepositoryFake(
        persistenceService: InMemoryPersistenceService(),
      );

      expect(await repository.restoreSession(), isNull);
    });

    test(
      'sign-out purges the marker — the next restore is signed out',
      () async {
        final persistence = InMemoryPersistenceService()
          ..sessionToken = AuthRepositoryFake.fakeSessionToken;
        final repository = AuthRepositoryFake(persistenceService: persistence);
        expect(await repository.restoreSession(), isNotNull);

        await repository.signOut();

        expect(persistence.sessionToken, isNull);
        expect(
          await AuthRepositoryFake(
            persistenceService: persistence,
          ).restoreSession(),
          isNull,
        );
      },
    );
  });
}
