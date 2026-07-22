import 'package:apparule/src/core/data/seed_json.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/comment.dart';
import 'package:apparule/src/features/feed/domain/designer_summary.dart';
import 'package:apparule/src/features/feed/domain/explore_results.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/domain/story_rail_entry.dart';
import 'package:flutter/services.dart';

/// Seed-backed fake (mobile-implementation.md §6): parses the web mock
/// seed narrative (assets/seed/dev/{me,designers,posts}.json — same ids,
/// counts and photography as `web/src/mocks/seed.ts`) and applies the web
/// store's SEMANTICS over it: viewer-scoped like/save projection, count
/// mutation on toggle, comment count == comment list, follow-graph-derived
/// feed and story rail, and explore's near-me tier re-rank. State lives
/// for the provider's keepAlive lifetime — a like on C2 is still liked on
/// C4 and on the next feed refresh.
class PostRepositoryFake implements PostRepository {
  PostRepositoryFake({AssetBundle? bundle, DateTime Function()? now})
    // Instance-scoped bundle, never the global rootBundle — its string
    // cache pins futures to the zone that first loaded them, which
    // deadlocks later widget tests (C6 wave finding).
    : _bundle = bundle ?? PlatformAssetBundle(),
      _now = now ?? DateTime.now;

  static const String _meAsset = 'assets/seed/dev/me.json';
  static const String _designersAsset = 'assets/seed/dev/designers.json';
  static const String _postsAsset = 'assets/seed/dev/posts.json';

  /// MI-8: a story ring is lit while the designer has <48h posts.
  static const Duration storyFreshWindow = Duration(hours: 48);

  final AssetBundle _bundle;
  final DateTime Function() _now;

  bool _loaded = false;
  final List<Post> _posts = <Post>[];
  final List<PostComment> _comments = <PostComment>[];
  final List<DesignerSummary> _designers = <DesignerSummary>[];
  final Set<String> _likedPostIds = <String>{};
  final Set<String> _savedPostIds = <String>{};
  final Set<String> _likedCommentIds = <String>{};
  final Set<String> _follows = <String>{};
  final Set<String> _seenStories = <String>{};
  ({String city, String state, String country})? _viewerLocation;
  final Map<String, ({String city, String state, String country})>
  _designerLocations =
      <String, ({String city, String state, String country})>{};
  final Map<String, String> _designerBios = <String, String>{};
  int _commentSequence = 0;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final now = _now();

    if (await loadSeedJson(_bundle, _meAsset) case final me?) {
      _follows.addAll((me['follows'] as List<dynamic>).cast<String>());
      _likedPostIds.addAll(
        (me['liked_post_ids'] as List<dynamic>).cast<String>(),
      );
      _savedPostIds.addAll(
        (me['saved_post_ids'] as List<dynamic>).cast<String>(),
      );
      if (me['profile_location'] case final Map<String, dynamic> location) {
        _viewerLocation = _locationOf(location);
      }
    }

    if (await loadSeedJson(_bundle, _designersAsset) case final seed?) {
      for (final entry in seed['designers'] as List<dynamic>) {
        final json = entry as Map<String, dynamic>;
        final location = _locationOf(
          json['location'] as Map<String, dynamic>,
        );
        final username = json['username'] as String;
        _designerLocations[username] = location;
        _designerBios[username] = (json['bio'] as String? ?? '').toLowerCase();
        _designers.add(
          DesignerSummary(
            username: username,
            displayName: json['display_name'] as String,
            locality: location.city,
            avatarUrl: json['avatar_url'] as String?,
            verified: json['verified'] as bool? ?? false,
          ),
        );
      }
    }

    if (await loadSeedJson(_bundle, _postsAsset) case final seed?) {
      for (final entry in seed['posts'] as List<dynamic>) {
        _posts.add(_postFromSeed(entry as Map<String, dynamic>, now));
      }
      for (final entry in seed['comments'] as List<dynamic>) {
        _comments.add(_commentFromSeed(entry as Map<String, dynamic>, now));
      }
    }
  }

  static ({String city, String state, String country}) _locationOf(
    Map<String, dynamic> json,
  ) => (
    city: json['city'] as String,
    state: json['state'] as String,
    country: json['country'] as String,
  );

  Post _postFromSeed(Map<String, dynamic> json, DateTime now) {
    final designer = json['designer'] as Map<String, dynamic>;
    return Post(
      id: json['id'] as String,
      designer: PostDesigner(
        id: designer['id'] as String,
        username: designer['username'] as String,
        displayName: designer['display_name'] as String,
        avatarUrl: designer['avatar_url'] as String?,
        verified: designer['verified'] as bool? ?? false,
      ),
      caption: json['caption'] as String,
      styleTags: (json['style_tags'] as List<dynamic>).cast<String>(),
      media: <PostMedia>[
        for (final media in json['media'] as List<dynamic>)
          PostMedia(
            url: (media as Map<String, dynamic>)['url'] as String,
            altText: media['alt_text'] as String,
          ),
      ],
      likeCount: (json['like_count'] as num).toInt(),
      commentCount: (json['comment_count'] as num).toInt(),
      basePriceCents: (json['base_price_cents'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'NGN',
      turnaroundDays: (json['turnaround_days'] as num?)?.toInt() ?? 0,
      createdAt: seedDaysAgo(now, json['created_days_ago'] as num),
    );
  }

  PostComment _commentFromSeed(Map<String, dynamic> json, DateTime now) {
    final author = json['author'] as Map<String, dynamic>;
    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      author: CommentAuthor(
        id: author['id'] as String,
        username: author['username'] as String,
        avatarUrl: author['avatar_url'] as String?,
      ),
      body: json['body'] as String,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      createdAt: seedDaysAgo(now, json['created_days_ago'] as num),
    );
  }

  /// Viewer-scoped projection (web store `viewPost` parity).
  Post _view(Post post) => post.copyWith(
    liked: _likedPostIds.contains(post.id),
    saved: _savedPostIds.contains(post.id),
  );

  Post _postById(String id) => _posts.firstWhere(
    (post) => post.id == id,
    orElse: () {
      throw StateError('Post not found: $id');
    },
  );

  @override
  Future<List<Post>> homeFeed() async {
    await _ensureLoaded();
    return <Post>[
      for (final post in _posts)
        if (_follows.contains(post.designer.username)) _view(post),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<StoryRailEntry>> storyRail() async {
    final feed = await homeFeed();
    final now = _now();
    final byUsername = <String, StoryRailEntry>{};
    // Feed is newest-first, so the first post seen per designer is their
    // newest — the story tap target.
    for (final post in feed) {
      final username = post.designer.username;
      final fresh = now.difference(post.createdAt) < storyFreshWindow;
      final existing = byUsername[username];
      byUsername[username] = StoryRailEntry(
        username: username,
        avatarUrl: post.designer.avatarUrl,
        newestPostId: existing?.newestPostId ?? post.id,
        unseen:
            ((existing?.unseen ?? false) || fresh) &&
            !_seenStories.contains(username),
      );
    }
    return byUsername.values.toList();
  }

  @override
  Future<void> markStorySeen(String username) async {
    _seenStories.add(username);
  }

  @override
  Future<ExploreResults> explore({
    String query = '',
    String? tag,
    bool nearMe = false,
  }) async {
    await _ensureLoaded();
    var posts = _posts.toList();
    final needle = query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      posts = posts
          .where(
            (post) =>
                post.caption.toLowerCase().contains(needle) ||
                post.designer.username.contains(needle) ||
                post.designer.displayName.toLowerCase().contains(needle) ||
                post.styleTags.any((t) => t.contains(needle)),
          )
          .toList();
    }
    if (tag != null) {
      posts = posts.where((post) => post.styleTags.contains(tag)).toList();
    }
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (nearMe && _viewerLocation != null) {
      // Proximity RANKING, not a hard gate: locationless designers simply
      // sort last; recency holds within a tier (stable mergeSort-free
      // approach: decorate + stable comparison on tier only).
      final home = _viewerLocation!;
      int tierOf(Post post) {
        final location = _designerLocations[post.designer.username];
        if (location == null || location.country != home.country) return 3;
        if (location.city == home.city && location.state == home.state) {
          return 0;
        }
        if (location.state == home.state) return 1;
        return 2;
      }

      final decorated =
          <(int, int, Post)>[
            for (final (index, post) in posts.indexed)
              (tierOf(post), index, post),
          ]..sort((a, b) {
            final byTier = a.$1.compareTo(b.$1);
            return byTier != 0 ? byTier : a.$2.compareTo(b.$2);
          });
      posts = <Post>[for (final entry in decorated) entry.$3];
    }
    final designers = needle.isEmpty
        ? const <DesignerSummary>[]
        : _designers
              .where(
                (designer) =>
                    designer.username.contains(needle) ||
                    designer.displayName.toLowerCase().contains(needle) ||
                    (_designerBios[designer.username] ?? '').contains(needle),
              )
              .map(
                (designer) => designer.copyWith(
                  viewerFollows: _follows.contains(designer.username),
                ),
              )
              .toList();
    return ExploreResults(
      posts: posts.map(_view).toList(),
      designers: designers,
    );
  }

  @override
  Future<Post> post(String id) async {
    await _ensureLoaded();
    return _view(_postById(id));
  }

  @override
  Future<Post> toggleLike(String id) async {
    await _ensureLoaded();
    final post = _postById(id);
    // Idempotent set semantics with a moving count (web `setEngagement`).
    final int delta;
    if (_likedPostIds.add(id)) {
      delta = 1;
    } else {
      _likedPostIds.remove(id);
      delta = -1;
    }
    final updated = post.copyWith(likeCount: post.likeCount + delta);
    _posts[_posts.indexOf(post)] = updated;
    return _view(updated);
  }

  @override
  Future<Post> toggleSave(String id) async {
    await _ensureLoaded();
    final post = _postById(id);
    if (!_savedPostIds.add(id)) _savedPostIds.remove(id);
    return _view(post);
  }

  @override
  Future<void> setFollow(String username, {required bool follow}) async {
    await _ensureLoaded();
    if (follow) {
      _follows.add(username);
    } else {
      _follows.remove(username);
    }
  }

  @override
  Future<List<PostComment>> comments(String postId) async {
    await _ensureLoaded();
    return <PostComment>[
      for (final comment in _comments)
        if (comment.postId == postId)
          comment.copyWith(liked: _likedCommentIds.contains(comment.id)),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<PostComment> addComment(String postId, String body) async {
    await _ensureLoaded();
    final post = _postById(postId);
    final comment = PostComment(
      id: 'cmt-local-${++_commentSequence}',
      postId: postId,
      // The signed-in §6 test user authors composer comments.
      author: const CommentAuthor(id: 'acc-kiki', username: 'kiki.adeyemi'),
      body: body,
      createdAt: _now(),
    );
    _comments.add(comment);
    // The web store's unit-gated invariant: count mirrors the list.
    _posts[_posts.indexOf(post)] = post.copyWith(
      commentCount: post.commentCount + 1,
    );
    return comment;
  }

  @override
  Future<PostComment> toggleCommentLike(String commentId) async {
    await _ensureLoaded();
    final index = _comments.indexWhere((comment) => comment.id == commentId);
    if (index < 0) throw StateError('Comment not found: $commentId');
    final comment = _comments[index];
    final liked = _likedCommentIds.add(commentId);
    if (!liked) _likedCommentIds.remove(commentId);
    final updated = comment.copyWith(
      likeCount: comment.likeCount + (liked ? 1 : -1),
    );
    _comments[index] = updated;
    return updated.copyWith(liked: liked);
  }
}
