import 'package:apparule/src/core/ui/google_auth_button.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/notched.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/throwing_auth_repository.dart';

void main() {
  group('SignInScreen (C1)', () {
    testWidgets(
      'renders wordmark, tagline, exactly one auth CTA, and legal links',
      (tester) async {
        await tester.pumpApp(const SignInScreen());

        expect(find.text('Apparule'), findsOneWidget);
        expect(
          find.text('Precision measurement meets social fashion'),
          findsOneWidget,
        );
        // X-1: exactly one auth CTA, and it is the Google one.
        expect(find.byType(GoogleAuthButton), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        // Legal-link canon: both policies, inline in the footer.
        expect(
          find.textContaining(
            'By continuing you agree to our',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Terms', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Privacy Policy', findRichText: true),
          findsOneWidget,
        );
        // Nothing from the retired password world (flows/auth.md §5).
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets('the CTA triggers the repository sign-in', (tester) async {
      final repository = AuthRepositoryFake();
      await tester.pumpApp(
        const SignInScreen(),
        authRepository: repository,
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(
        await repository.restoreSession(),
        AuthRepositoryFake.seedSession,
      );
    });

    testWidgets('a network failure renders the offline notice (flows §4)', (
      tester,
    ) async {
      await tester.pumpApp(
        const SignInScreen(),
        authRepository: ThrowingAuthRepository(
          const AuthException(AuthErrorCode.network),
        ),
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(
        find.text("You're offline — check your connection and try again."),
        findsOneWidget,
      );
    });

    testWidgets('a disabled account renders its notice (flows §4)', (
      tester,
    ) async {
      await tester.pumpApp(
        const SignInScreen(),
        authRepository: ThrowingAuthRepository(
          const AuthException(AuthErrorCode.userDisabled),
        ),
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(find.text('This account has been disabled.'), findsOneWidget);
    });

    testWidgets('a dismissed sheet leaves the screen unchanged (flows §4)', (
      tester,
    ) async {
      await tester.pumpApp(
        const SignInScreen(),
        authRepository: ThrowingAuthRepository(
          const AuthException(AuthErrorCode.canceled),
        ),
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        find.text("You're offline — check your connection and try again."),
        findsNothing,
      );
      expect(
        find.text('Something went wrong signing you in. Try again.'),
        findsNothing,
      );
    });
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await tester.pumpApp(const SignInScreen());
    await expectContentClearOfTopInsets(tester);
  });
}
