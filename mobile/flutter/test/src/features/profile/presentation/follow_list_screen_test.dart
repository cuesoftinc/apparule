import 'package:apparule/src/core/ui/user_row.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_screen.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/notched.dart';

/// C12 followers/following: count-titled tabs over UserRow lists, the
/// MI-7 morph mutating the same graph every header derives from.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Future<void> pump(
    WidgetTester tester, {
    FollowListKind kind = FollowListKind.followers,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpApp(
      FollowListScreen(username: 'amara.designs', initialKind: kind),
      postRepository: PostRepositoryFake(now: () => pinned),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('followers mirror the seed graph, designers carry the '
      'morph, community rows stay plain', (tester) async {
    await pump(tester);

    expect(find.text('8 followers'), findsOneWidget);
    expect(find.text('2 following'), findsOneWidget);
    expect(find.byType(UserRow), findsNWidgets(8));
    // Designer follower rows carry meta + morph; community rows none.
    expect(find.text('Tunde Okonkwo · designer'), findsOneWidget);
    expect(find.text('Ada Eze'), findsOneWidget);
    // kiki follows none of amara's followers → all designer rows read
    // Follow (tunde/bisi/eniola aren't followed by kiki... bisi is).
    expect(find.text('Following'), findsOneWidget); // maisonbisi
  });

  testWidgets('the tabs switch lists', (tester) async {
    await pump(tester);

    await tester.tap(find.text('2 following'));
    await tester.pumpAndSettle();

    // amara follows tunde.o + maisonbisi.
    expect(find.byType(UserRow), findsNWidgets(2));
    expect(find.text('tunde.o'), findsOneWidget);
    expect(find.text('maisonbisi'), findsOneWidget);
  });

  testWidgets('MI-7 from a row: Follow morphs and the graph moves', (
    tester,
  ) async {
    await pump(tester, kind: FollowListKind.following);

    // tunde.o is not followed by the viewer → gradient Follow.
    final followButtons = find.text('Follow');
    expect(followButtons, findsOneWidget);

    await tester.tap(followButtons);
    await tester.pumpAndSettle();
    expect(find.text('Follow'), findsNothing);
    expect(find.text('Following'), findsNWidgets(2));
  });

  testWidgets('unfollow from a row goes through the confirm sheet', (
    tester,
  ) async {
    await pump(tester, kind: FollowListKind.following);

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(find.text('Unfollow?'), findsOneWidget);

    await tester.tap(find.text('Unfollow @maisonbisi'));
    await tester.pumpAndSettle();
    expect(find.text('Following'), findsNothing);
    expect(find.text('Follow'), findsNWidgets(2));
  });

  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await pump(tester);
    expectNoContentInTopInset(tester);
  });
}
