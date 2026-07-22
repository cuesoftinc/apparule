import 'package:apparule/src/app/app.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/ui/app_shell.dart';
import 'package:apparule/src/core/ui/tab_bar.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boot smoke: the app builds to the five-tab shell over fakes', (
    tester,
  ) async {
    // Mirrors main_dev.dart's composition (bootstrap itself calls runApp,
    // so the test pumps the identical ProviderScope by hand) — seeded
    // signed in as the §6 test user, the restored-session boot path.
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeRepositoryOverrides(
          authRepository: AuthRepositoryFake(
            initialSession: AuthRepositoryFake.seedSession,
          ),
        ),
        child: const ApparuleApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(AppTabBar), findsOneWidget);
    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });
}
