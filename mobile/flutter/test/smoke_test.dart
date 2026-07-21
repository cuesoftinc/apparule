import 'package:apparule/src/app/app.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/ui/app_shell.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boot smoke: the app builds to the five-tab shell over fakes', (
    tester,
  ) async {
    // Mirrors main_dev.dart's composition (bootstrap itself calls runApp,
    // so the test pumps the identical ProviderScope by hand).
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeRepositoryOverrides(),
        child: const ApparuleApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });
}
