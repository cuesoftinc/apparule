import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/throwing_auth_repository.dart';

void main() {
  group('SignInViewModel', () {
    test(
      'continueWithGoogle lands the seeded session on the session stream',
      () async {
        final container = ProviderContainer(
          // An explicit in-memory fake: the default binds the secure-
          // storage persistence seam, which has no plugin in pure Dart
          // tests.
          overrides: fakeRepositoryOverrides(
            authRepository: AuthRepositoryFake(),
          ),
        );
        addTearDown(container.dispose);
        final session = container.listen(authSessionProvider, (_, _) {});

        expect(await container.read(authSessionProvider.future), isNull);

        await container
            .read(signInViewModelProvider.notifier)
            .continueWithGoogle();
        await pumpEventQueue();

        expect(container.read(signInViewModelProvider).hasError, isFalse);
        expect(session.read().value, AuthRepositoryFake.seedSession);
      },
    );

    test(
      'a dismissed sheet resolves silently — no error state (flows §4)',
      () async {
        final container = ProviderContainer(
          overrides: fakeRepositoryOverrides(
            authRepository: ThrowingAuthRepository(
              const AuthException(AuthErrorCode.canceled),
            ),
          ),
        );
        addTearDown(container.dispose);

        await container
            .read(signInViewModelProvider.notifier)
            .continueWithGoogle();

        final state = container.read(signInViewModelProvider);
        expect(state.hasError, isFalse);
        expect(state.isLoading, isFalse);
      },
    );

    test(
      'a network failure surfaces as an AuthException error state',
      () async {
        final container = ProviderContainer(
          overrides: fakeRepositoryOverrides(
            authRepository: ThrowingAuthRepository(
              const AuthException(AuthErrorCode.network),
            ),
          ),
        );
        addTearDown(container.dispose);

        await container
            .read(signInViewModelProvider.notifier)
            .continueWithGoogle();

        final state = container.read(signInViewModelProvider);
        expect(state.hasError, isTrue);
        expect(
          state.error,
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.network,
          ),
        );
      },
    );
  });
}
