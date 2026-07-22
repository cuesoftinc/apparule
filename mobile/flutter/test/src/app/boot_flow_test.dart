import 'dart:async';

import 'package:apparule/src/app/boot_screen.dart';
import 'package:apparule/src/core/ui/app_shell.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_screen.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/boot_app.dart';
import '../../helpers/in_memory_persistence.dart';

/// The cold-start contract (boot-flow directive 2026-07-22): splash →
/// session-restore gate → C1 when no session / straight into the tab
/// shell when one persisted; the fake persists its session through the
/// same seam the real flow uses, so sign-in survives relaunch and
/// sign-out purges it — web TEST_MODE parity.
void main() {
  group('cold start', () {
    testWidgets(
      'a first-ever launch restores nothing and lands on C1 — with the '
      'boot frame, never a tab-shell or C1 flash, while restoring',
      (tester) async {
        final persistence = InMemoryPersistenceService();
        await pumpBootedApp(
          tester,
          persistenceService: persistence,
          settle: false,
        );

        // First frame: the restore gate — no router surface yet.
        expect(find.byType(BootScreen), findsOneWidget);
        expect(find.byType(SignInScreen), findsNothing);
        expect(find.byType(AppShell), findsNothing);

        await tester.pumpAndSettle();

        expect(find.byType(SignInScreen), findsOneWidget);
        expect(find.byType(BootScreen), findsNothing);
      },
    );

    testWidgets('a persisted session restores straight into the tab shell', (
      tester,
    ) async {
      final persistence = InMemoryPersistenceService()
        ..sessionToken = AuthRepositoryFake.fakeSessionToken;

      await pumpBootedApp(
        tester,
        persistenceService: persistence,
        preferences: <String, Object>{'first_action_seen': true},
      );

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });
  });

  group('session persistence', () {
    testWidgets('sign-in persists the session marker; the next launch '
        'restores it without C1', (tester) async {
      final persistence = InMemoryPersistenceService();

      await pumpBootedApp(
        tester,
        persistenceService: persistence,
        preferences: <String, Object>{'first_action_seen': true},
      );
      expect(find.byType(SignInScreen), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(persistence.sessionToken, AuthRepositoryFake.fakeSessionToken);

      // "Relaunch": a fresh app over the SAME persistence.
      await pumpBootedApp(
        tester,
        persistenceService: persistence,
        preferences: <String, Object>{'first_action_seen': true},
      );

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('sign-out purges the persisted session and lands on C1 — '
        'the next launch boots signed out', (tester) async {
      final persistence = InMemoryPersistenceService()
        ..sessionToken = AuthRepositoryFake.fakeSessionToken;

      await pumpBootedApp(
        tester,
        persistenceService: persistence,
        preferences: <String, Object>{'first_action_seen': true},
      );
      expect(find.byType(HomeFeedScreen), findsOneWidget);

      // B7 Account & data → Log out (the one sign-out affordance).
      routerOf(tester).go('/settings/account');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(persistence.sessionToken, isNull);

      // "Relaunch": still signed out.
      await pumpBootedApp(tester, persistenceService: persistence);
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('boot frame', () {
    testWidgets('shows no spinner before ~300ms and one after, while the '
        'restore is still pending', (tester) async {
      final gate = _PendingRestoreAuthRepository();
      await pumpBootedApp(tester, authRepository: gate, settle: false);

      expect(find.byType(BootScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pump(kBootSpinnerDelay + const Duration(milliseconds: 50));

      expect(find.byType(BootScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete(null);
      await tester.pumpAndSettle();

      expect(find.byType(BootScreen), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('a slow restore that resolves signed-in mounts the shell '
        'without ever showing C1', (tester) async {
      final gate = _PendingRestoreAuthRepository();
      await pumpBootedApp(
        tester,
        authRepository: gate,
        preferences: <String, Object>{'first_action_seen': true},
        settle: false,
      );

      expect(find.byType(BootScreen), findsOneWidget);

      gate.complete(AuthRepositoryFake.seedSession);
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });
  });
}

/// A restore that stays pending until the test releases it — the seam for
/// asserting the boot frame's states while the gate is genuinely open.
class _PendingRestoreAuthRepository implements AuthRepository {
  final Completer<AuthSession?> _restore = Completer<AuthSession?>();

  void complete(AuthSession? session) => _restore.complete(session);

  @override
  Future<AuthSession?> restoreSession() => _restore.future;

  @override
  Future<AuthSession> signInWithGoogle() async =>
      AuthRepositoryFake.seedSession;

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthSession?> sessionChanges() => const Stream<AuthSession?>.empty();
}
