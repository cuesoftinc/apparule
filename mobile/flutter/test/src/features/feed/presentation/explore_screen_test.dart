import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/post_detail_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';

/// C3 over the seeded fake: browse grid, sectioned search results with
/// the MI-7 follow morph, per-section empties. 390px canvas width.
void main() {
  Future<void> bootToExplore(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
    );
    routerOf(tester).go(const ExploreRoute().location);
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  testWidgets('browse renders the seeded 3-col grid with the filter '
      'chips', (tester) async {
    await bootToExplore(tester);

    expect(
      find.bySemanticsLabel('Model in an ankara maxi skirt on the runway'),
      findsOneWidget,
    );
    expect(find.text('Near me'), findsOneWidget);
    expect(find.text('Ankara'), findsOneWidget);
  });

  testWidgets('a grid tile opens C4', (tester) async {
    await bootToExplore(tester);

    await tester.tap(
      find.bySemanticsLabel('Model in an ankara maxi skirt on the runway'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailScreen), findsOneWidget);
  });

  testWidgets('search sections designers above outfits, with the MI-7 '
      'follow morph mutating the graph', (tester) async {
    await bootToExplore(tester);
    await search(tester, 'ankara');

    expect(find.text('Designers'), findsOneWidget);
    expect(find.text('amara.designs'), findsOneWidget);
    // kiki already follows amara — the morph starts at Following.
    expect(find.text('Following'), findsOneWidget);

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('a no-match query renders the search empty state', (
    tester,
  ) async {
    await bootToExplore(tester);
    await search(tester, 'zzzz');

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No results for "zzzz"'), findsOneWidget);
    expect(find.text('Clear search'), findsOneWidget);
  });
}
