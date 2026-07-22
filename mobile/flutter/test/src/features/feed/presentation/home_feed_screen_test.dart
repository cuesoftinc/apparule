import 'package:apparule/src/core/ui/caught_up_divider.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/post_card.dart';
import 'package:apparule/src/core/ui/story_rail_item.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/notifications_screen.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C2 over the seeded fake — story rail + PostCard column, interactions
/// mutating fake state. Runs at the 390px canvas width: any overflow
/// fails the test (the C6-noted placeholder overflow died with the
/// placeholder this wave replaced).
void main() {
  Future<void> bootToFeed(
    WidgetTester tester, {
    PostRepositoryFake? postRepository,
    Size size = const Size(390, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      postRepository: postRepository,
    );
  }

  testWidgets('renders the story rail and the followed-designer feed at '
      '390px without overflow', (tester) async {
    await bootToFeed(tester);

    // Story rail: kiki's two followed designers.
    expect(find.byType(StoryRailItem), findsNWidgets(2));

    // The newest followed post leads the column (web feed() parity).
    final firstCard = tester.widget<PostCard>(find.byType(PostCard).first);
    expect(firstCard.username, 'amara.designs');
    expect(firstCard.likeCount, 18);
    expect(firstCard.commentCount, 2);
  });

  testWidgets('the like toggle is a real fake-state mutation', (
    tester,
  ) async {
    final repository = PostRepositoryFake();
    await bootToFeed(tester, postRepository: repository);

    expect(find.text('18 likes'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Like').first);
    await tester.pumpAndSettle();
    expect(find.text('19 likes'), findsOneWidget);

    // The repository — not widget state — carries the change.
    final post = await repository.post('post-print-couple');
    expect(post.liked, isTrue);
    expect(post.likeCount, 19);
  });

  testWidgets('the save toggle mutates fake state and shows the MI-3 '
      'first-save toast exactly once per install', (tester) async {
    final repository = PostRepositoryFake();
    await bootToFeed(tester, postRepository: repository);

    await tester.tap(find.bySemanticsLabel('Save').first);
    await tester.pumpAndSettle();

    // Repository truth mutated…
    final post = await repository.post('post-print-couple');
    expect(post.saved, isTrue);
    // …and the first-ever save announces itself (web first-save.ts
    // parity), with the View action into the profile.
    expect(find.text('Saved to your looks'), findsOneWidget);

    // Dismiss the snack (with semantics enabled — always, in tests —
    // action-bearing snacks persist for accessible navigation), then
    // unsave and save again: no re-toast (persisted install-level gate;
    // un-save itself never toasts).
    await tester.drag(find.text('Saved to your looks'), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(find.text('Saved to your looks'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Remove from saved').first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Save').first);
    await tester.pumpAndSettle();
    expect(find.text('Saved to your looks'), findsNothing);
  });

  testWidgets('a C2 like reads back on the C9 liked-outfits grid', (
    tester,
  ) async {
    await bootToFeed(tester);

    // post-print-couple is NOT seeded liked — like it on the feed.
    await tester.tap(find.bySemanticsLabel('Like').first);
    await tester.pumpAndSettle();

    routerOf(tester).go(const ProfileRoute().location);
    await tester.pumpAndSettle();

    // The non-designer profile's first tab IS the liked grid — the tile
    // appears without any manual refresh (live-QA: engagement reads
    // back on every surface).
    expect(
      find.bySemanticsLabel('Couple wearing matching African print outfits'),
      findsOneWidget,
    );
  });

  testWidgets('scrolling to the end lands on the MI-6 caught-up divider', (
    tester,
  ) async {
    await bootToFeed(tester);

    await tester.scrollUntilVisible(
      find.byType(CaughtUpDivider),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('a PostCard header identity opens the designer C9 profile', (
    tester,
  ) async {
    await bootToFeed(tester);

    // The live-QA defect: the header avatar/name navigated nowhere.
    await tester.tap(
      find.bySemanticsLabel('View amara.designs profile').first,
    );
    await tester.pumpAndSettle();

    final profile = tester.widget<PublicProfileScreen>(
      find.byType(PublicProfileScreen),
    );
    expect(profile.username, 'amara.designs');
  });

  testWidgets('a story ring opens the designer C9 profile and consumes '
      'the ring', (tester) async {
    final repository = PostRepositoryFake();
    await bootToFeed(tester, postRepository: repository);

    final firstStory = tester.widget<StoryRailItem>(
      find.byType(StoryRailItem).first,
    );
    expect(firstStory.state, StoryRailItemState.unseen);

    await tester.tap(find.byType(StoryRailItem).first);
    await tester.pumpAndSettle();

    // Web FeedView parity: the rail item links the designer profile.
    final profile = tester.widget<PublicProfileScreen>(
      find.byType(PublicProfileScreen),
    );
    expect(profile.username, firstStory.username);

    // The ring was consumed on the way (repository state, not widget).
    final stories = await repository.storyRail();
    expect(
      stories
          .firstWhere((entry) => entry.username == firstStory.username)
          .unseen,
      isFalse,
    );
  });

  testWidgets('the top-bar bell opens C10', (tester) async {
    await bootToFeed(tester);

    await tester.tap(find.bySemanticsLabel('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
  });

  testWidgets('an empty follow graph renders the feed empty state', (
    tester,
  ) async {
    await bootToFeed(
      tester,
      postRepository: PostRepositoryFake(bundle: _EmptyAssetBundle()),
    );

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Follow designers to fill your feed'), findsOneWidget);
  });
  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToFeed(tester);
    await expectContentClearOfTopInsets(tester);
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
