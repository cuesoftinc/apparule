import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seeded post fake carries the web mock narrative and the web
/// store's SEMANTICS: viewer projection, count mutation on toggle,
/// comment count == comment list, follow-derived feed/rail, near-me
/// tier re-rank (web/src/mocks/{seed,store}.ts parity).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PostRepositoryFake fake() =>
      PostRepositoryFake(now: () => DateTime.utc(2026, 7, 22, 12));

  group('seed narrative (web parity)', () {
    test(
      'the home feed is the followed designers only, newest first', //
      () async {
        final repository = fake();
        final feed = await repository.homeFeed();

        // kiki follows amara.designs + maisonbisi → 7 of the 11 posts.
        expect(feed, hasLength(7));
        expect(
          feed.map((post) => post.designer.username).toSet(),
          <String>{'amara.designs', 'maisonbisi'},
        );
        expect(feed.first.id, 'post-print-couple'); // 1d — newest followed
        expect(feed.last.id, 'post-evening-gown'); // 20d — oldest followed
      },
    );

    test('viewer engagement projects from the seeded like/save sets', () async {
      final repository = fake();
      final feed = await repository.homeFeed();
      final asooke = feed.singleWhere((post) => post.id == 'post-asooke-set');
      final bridal = feed.singleWhere((post) => post.id == 'post-bridal-gown');

      expect(asooke.liked, isTrue);
      expect(asooke.saved, isFalse);
      expect(bridal.liked, isTrue);
      expect(bridal.saved, isTrue);
    });

    test('comment counts mirror the comment lists exactly (the web '
        'store invariant)', () async {
      final repository = fake();
      final explore = await repository.explore();

      expect(explore.posts, hasLength(11));
      for (final post in explore.posts) {
        final comments = await repository.comments(post.id);
        expect(
          comments,
          hasLength(post.commentCount),
          reason: '${post.id} count must match its comment list',
        );
      }
    });
  });

  group('engagement mutations', () {
    test('toggleLike moves the count and persists across reads', () async {
      final repository = fake();
      var post = await repository.post('post-print-couple');
      expect(post.liked, isFalse);
      expect(post.likeCount, 18);

      post = await repository.toggleLike('post-print-couple');
      expect(post.liked, isTrue);
      expect(post.likeCount, 19);

      // The mutation is repository state, not a response-local echo.
      final feed = await repository.homeFeed();
      final fromFeed = feed.singleWhere((p) => p.id == 'post-print-couple');
      expect(fromFeed.liked, isTrue);
      expect(fromFeed.likeCount, 19);

      post = await repository.toggleLike('post-print-couple');
      expect(post.liked, isFalse);
      expect(post.likeCount, 18);
    });

    test('toggleSave flips the viewer save', () async {
      final repository = fake();
      var post = await repository.toggleSave('post-print-couple');
      expect(post.saved, isTrue);
      post = await repository.toggleSave('post-print-couple');
      expect(post.saved, isFalse);
    });

    test('addComment appends and bumps the count in lockstep', () async {
      final repository = fake();
      final before = await repository.post('post-ankara-gown');

      final comment = await repository.addComment(
        'post-ankara-gown',
        'Beautiful drape!',
      );
      expect(comment.author.username, 'kiki.adeyemi');

      final after = await repository.post('post-ankara-gown');
      final comments = await repository.comments('post-ankara-gown');
      expect(after.commentCount, before.commentCount + 1);
      expect(comments, hasLength(after.commentCount));
      expect(comments.last.body, 'Beautiful drape!');
    });

    test('toggleCommentLike moves the heart + count', () async {
      final repository = fake();
      var comment = await repository.toggleCommentLike('cmt-1');
      expect(comment.liked, isTrue);
      expect(comment.likeCount, 5);
      comment = await repository.toggleCommentLike('cmt-1');
      expect(comment.liked, isFalse);
      expect(comment.likeCount, 4);
    });

    test('setFollow re-derives the feed from the graph', () async {
      final repository = fake();
      await repository.setFollow('tunde.o', follow: true);
      var feed = await repository.homeFeed();
      expect(feed, hasLength(10)); // + tunde's 3 posts

      await repository.setFollow('amara.designs', follow: false);
      feed = await repository.homeFeed();
      expect(feed, hasLength(7)); // − amara's 3
    });
  });

  group('story rail (MI-8)', () {
    test('rings light for <48h posts and dim once seen', () async {
      final repository = fake();
      var rail = await repository.storyRail();

      expect(rail, hasLength(2));
      final amara = rail.singleWhere(
        (entry) => entry.username == 'amara.designs',
      );
      final bisi = rail.singleWhere((entry) => entry.username == 'maisonbisi');
      expect(amara.unseen, isTrue); // print-couple is 1d old
      expect(amara.newestPostId, 'post-print-couple');
      expect(bisi.unseen, isFalse); // newest bisi post is 4d old

      await repository.markStorySeen('amara.designs');
      rail = await repository.storyRail();
      expect(
        rail.singleWhere((entry) => entry.username == 'amara.designs').unseen,
        isFalse,
      );
    });
  });

  group('explore (C3)', () {
    test('a query returns sectioned designers + posts', () async {
      final repository = fake();
      final results = await repository.explore(query: 'ankara');

      // amara matches via her bio (web /designers?q= behavior).
      expect(
        results.designers.map((designer) => designer.username),
        contains('amara.designs'),
      );
      expect(
        results.posts.map((post) => post.id),
        containsAll(<String>['post-ankara-gown', 'post-fabric-drop']),
      );
    });

    test('near-me re-RANKS (city > state > country), never filters', () async {
      final repository = fake();

      // Recency order: the Abuja atelier post (0.3d) leads.
      final recency = await repository.explore();
      expect(recency.posts.first.id, 'post-atelier-abuja');

      // Near me (kiki is Lagos): eniola re-ranks below every Lagos
      // designer but is still present — ranking, not a gate.
      final nearMe = await repository.explore(nearMe: true);
      expect(nearMe.posts, hasLength(11));
      expect(nearMe.posts.first.id, 'post-print-couple');
      expect(nearMe.posts.last.id, 'post-atelier-abuja');
    });

    test('tag chips filter by style tag', () async {
      final repository = fake();
      final results = await repository.explore(tag: 'bridal');
      expect(results.posts.map((post) => post.id), <String>[
        'post-bridal-gown',
      ]);
    });

    test('follow state rides the designer rows', () async {
      final repository = fake();
      var results = await repository.explore(query: 'amara');
      expect(results.designers.single.viewerFollows, isTrue);

      await repository.setFollow('amara.designs', follow: false);
      results = await repository.explore(query: 'amara');
      expect(results.designers.single.viewerFollows, isFalse);
    });
  });

  test('a prod bundle (no dev seeds) degrades to empty domains', () async {
    final repository = PostRepositoryFake(bundle: _EmptyAssetBundle());
    expect(await repository.homeFeed(), isEmpty);
    expect(await repository.storyRail(), isEmpty);
    expect((await repository.explore()).posts, isEmpty);
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
