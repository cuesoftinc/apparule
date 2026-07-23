import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/presentation/engagement_actions.dart';
import 'package:apparule/src/features/feed/presentation/explore_view_model.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_view_model.dart';
import 'package:apparule/src/features/feed/presentation/post_detail_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_persistence.dart';

/// EngagementActions two-surface contract (CLASS 1 lock): ONE container,
/// keep-alive listeners on the mutated provider and EVERY declared
/// derivation — homeFeed, postDetail(id), profile — one mutation, all
/// rebuild with the new state. This is the shape the always-mounted
/// shell exercises on device (Riverpod 3 pauses, never disposes).
/// The C15 publish carries its own declared fan-out (feed + explore +
/// own-profile grid) — pinned by the `createPost` group below.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const postId = 'post-print-couple';

  late ProviderContainer container;
  late int feedRebuilds;
  late int detailRebuilds;
  late int profileRebuilds;

  setUp(() async {
    container = ProviderContainer(
      overrides: fakeRepositoryOverrides(
        persistenceService: InMemoryPersistenceService(),
        postRepository: PostRepositoryFake(
          now: () => DateTime.utc(2026, 7, 22, 12),
        ),
      ),
    );
    addTearDown(container.dispose);

    feedRebuilds = 0;
    detailRebuilds = 0;
    profileRebuilds = 0;
    // Keep-alive listeners on every declared fan-out surface — the
    // paused-sibling stand-ins.
    container
      ..listen(homeFeedViewModelProvider, (previous, next) {
        if (next.hasValue) feedRebuilds++;
      })
      ..listen(postDetailViewModelProvider(postId), (previous, next) {
        if (next.hasValue) detailRebuilds++;
      })
      ..listen(profileViewModelProvider, (previous, next) {
        if (next.hasValue) profileRebuilds++;
      });

    // Settle the initial derivations.
    await container.read(homeFeedViewModelProvider.future);
    await container.read(postDetailViewModelProvider(postId).future);
    await container.read(profileViewModelProvider.future);
    feedRebuilds = 0;
    detailRebuilds = 0;
    profileRebuilds = 0;
  });

  test('toggleLike: one mutation, all three surfaces re-derive', () async {
    await container.read(engagementActionsProvider.notifier).toggleLike(postId);

    final feed = await container.read(homeFeedViewModelProvider.future);
    final detail = await container.read(
      postDetailViewModelProvider(postId).future,
    );
    final profile = await container.read(profileViewModelProvider.future);

    final fromFeed = feed.posts.singleWhere((post) => post.id == postId);
    expect(fromFeed.liked, isTrue);
    expect(fromFeed.likeCount, 19);
    expect(detail.liked, isTrue);
    // The C9 liked grid (non-designer first tab) gained the post — the
    // on-device D01 defect surface.
    expect(profile?.gridPosts.map((post) => post.id), contains(postId));

    expect(feedRebuilds, greaterThanOrEqualTo(1));
    expect(detailRebuilds, greaterThanOrEqualTo(1));
    expect(profileRebuilds, greaterThanOrEqualTo(1));
  });

  test('toggleSave: the C9 saved-looks grid re-derives', () async {
    await container.read(engagementActionsProvider.notifier).toggleSave(postId);

    final profile = await container.read(profileViewModelProvider.future);
    final detail = await container.read(
      postDetailViewModelProvider(postId).future,
    );

    expect(detail.saved, isTrue);
    expect(profile?.savedPosts.map((post) => post.id), contains(postId));
    expect(profileRebuilds, greaterThanOrEqualTo(1));
  });

  test(
    'addComment: the count echoes across feed and detail (D33)', //
    () async {
      final before = await container.read(
        postDetailViewModelProvider(postId).future,
      );

      await container
          .read(engagementActionsProvider.notifier)
          .addComment(postId, 'Beautiful drape!');

      final feed = await container.read(homeFeedViewModelProvider.future);
      final detail = await container.read(
        postDetailViewModelProvider(postId).future,
      );

      expect(detail.commentCount, before.commentCount + 1);
      expect(
        feed.posts.singleWhere((post) => post.id == postId).commentCount,
        before.commentCount + 1,
      );
      expect(feedRebuilds, greaterThanOrEqualTo(1));
    },
  );

  test('a failed mutation leaves every surface at the old truth', () async {
    final repository =
        container.read(postRepositoryProvider) as PostRepositoryFake
          ..failNext = Exception('server 500');

    await expectLater(
      container.read(engagementActionsProvider.notifier).toggleLike(postId),
      throwsException,
    );

    final feed = await container.read(homeFeedViewModelProvider.future);
    expect(feed.posts.singleWhere((post) => post.id == postId).liked, isFalse);
    expect(repository.failNext, isNull);
  });

  group('createPost (C15) — the declared create fan-out', () {
    const media = <PostMedia>[
      PostMedia(url: '/demo/outfit-w16.jpg', altText: 'Outfit by Kiki'),
    ];

    late ProviderContainer container;
    late PostRepositoryFake repository;
    late int feedRebuilds;
    late int exploreRebuilds;
    late int profileRebuilds;

    setUp(() async {
      repository = PostRepositoryFake(
        now: () => DateTime.utc(2026, 7, 22, 12),
        uploadDelay: Duration.zero,
      );
      container = ProviderContainer(
        overrides: fakeRepositoryOverrides(
          persistenceService: InMemoryPersistenceService(),
          postRepository: repository,
          // The designer perspective — the C9 first grid tab derives
          // from `postsBy(viewer)` only while the earnings side says
          // designer (the chooser's C15 gate).
          earningsRepository: EarningsRepositoryFake(
            viewer: 'amara.designs',
            resolveDelay: Duration.zero,
          ),
        ),
      );
      addTearDown(container.dispose);

      feedRebuilds = 0;
      exploreRebuilds = 0;
      profileRebuilds = 0;
      container
        ..listen(homeFeedViewModelProvider, (previous, next) {
          if (next.hasValue) feedRebuilds++;
        })
        ..listen(exploreViewModelProvider(), (previous, next) {
          if (next.hasValue) exploreRebuilds++;
        })
        ..listen(profileViewModelProvider, (previous, next) {
          if (next.hasValue) profileRebuilds++;
        });

      await container.read(homeFeedViewModelProvider.future);
      await container.read(exploreViewModelProvider().future);
      await container.read(profileViewModelProvider.future);
      feedRebuilds = 0;
      exploreRebuilds = 0;
      profileRebuilds = 0;
    });

    test('one publish — the post appears on the feed AND the own-profile '
        'grid (and explore), every surface re-derived', () async {
      final created = await container
          .read(engagementActionsProvider.notifier)
          .createPost(
            caption: 'Fresh agbada drop',
            media: media,
            snapshotSessionId: 'ms-vault-latest',
          );

      final feed = await container.read(homeFeedViewModelProvider.future);
      final explore = await container.read(exploreViewModelProvider().future);
      final profile = await container.read(profileViewModelProvider.future);

      // The two-surface acceptance: feed top + own-profile grid.
      expect(feed.posts.first.id, created.id);
      expect(profile?.gridPosts.map((post) => post.id), contains(created.id));
      expect(profile?.postsCount, greaterThanOrEqualTo(1));
      // Explore's recency grid gained it too (declared member #3).
      expect(explore.posts.map((post) => post.id), contains(created.id));
      // The publish carries the vault snapshot ref (M-11 differentiator).
      expect(feed.posts.first.snapshotSessionId, 'ms-vault-latest');

      expect(feedRebuilds, greaterThanOrEqualTo(1));
      expect(exploreRebuilds, greaterThanOrEqualTo(1));
      expect(profileRebuilds, greaterThanOrEqualTo(1));
    });

    test('a failed publish leaves every surface without the post', () async {
      repository.failNext = Exception('server 500');

      await expectLater(
        container
            .read(engagementActionsProvider.notifier)
            .createPost(caption: 'Never lands', media: media),
        throwsException,
      );

      final feed = await container.read(homeFeedViewModelProvider.future);
      expect(
        feed.posts.map((post) => post.caption),
        isNot(contains('Never lands')),
      );
      expect(repository.failNext, isNull);
    });
  });
}
