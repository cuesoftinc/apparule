import 'package:apparule/src/core/data/fail_next_seam.dart';
import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/core/data/seed_json.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/comment.dart';
import 'package:apparule/src/features/feed/domain/designer_summary.dart';
import 'package:apparule/src/features/feed/domain/explore_results.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/domain/public_profile.dart';
import 'package:apparule/src/features/feed/domain/report_reason.dart';
import 'package:apparule/src/features/feed/domain/story_rail_entry.dart';
import 'package:apparule/src/features/feed/domain/user_summary.dart';
import 'package:flutter/services.dart';

/// Seed-backed fake (mobile-implementation.md §6): parses the web mock
/// seed narrative (assets/seed/dev/{me,designers,posts}.json — same ids,
/// counts and photography as `web/src/mocks/seed.ts`) and applies the web
/// store's SEMANTICS over it: viewer-scoped like/save projection, count
/// mutation on toggle, comment count == comment list, follow-graph-derived
/// feed and story rail, and explore's near-me tier re-rank. State lives
/// for the provider's keepAlive lifetime; with a `persistence` seam bound
/// (di.dart binds the real service) the viewer's like/save sets and
/// follow list also survive a restart — a like on C2 is still liked on
/// C4, on the next feed refresh, AND on tomorrow's launch (CLASS 1,
/// D01's restart half).
class PostRepositoryFake with FailNextSeam implements PostRepository {
  PostRepositoryFake({
    AssetBundle? bundle,
    DateTime Function()? now,
    this._persistence,
    this.uploadDelay = const Duration(milliseconds: 900),
  })
    // Instance-scoped bundle, never the global rootBundle — its string
    // cache pins futures to the zone that first loaded them, which
    // deadlocks later widget tests (C6 wave finding).
    : _bundle = bundle ?? PlatformAssetBundle(),
       _now = now ?? DateTime.now;

  static const String _meAsset = 'assets/seed/dev/me.json';
  static const String _designersAsset = 'assets/seed/dev/designers.json';
  static const String _postsAsset = 'assets/seed/dev/posts.json';
  static const String _accountsAsset = 'assets/seed/dev/accounts.json';

  /// MI-8: a story ring is lit while the designer has <48h posts.
  static const Duration storyFreshWindow = Duration(hours: 48);

  final AssetBundle _bundle;
  final DateTime Function() _now;
  final PersistenceService? _persistence;

  /// The C15 publish's simulated upload beat: [createPost] resolves
  /// after this pause, so the composer's per-tile "Uploading…" strips
  /// and loading CTA are a lived state on the dev flavor
  /// (`EarningsRepositoryFake.resolveDelay` precedent — zero in tests
  /// that drive real async).
  final Duration uploadDelay;

  /// The one in-flight load — concurrent first callers (two providers
  /// watching one keepAlive fake) must all await the SAME parse instead
  /// of the second reading half-loaded state; once loaded, callers get
  /// a fresh completed future built in THEIR zone, so a fake
  /// pre-arranged inside `tester.runAsync` never hands the FakeAsync
  /// test zone a future pinned to another zone (both are profile-wave
  /// findings — the same trap as the C6 rootBundle string cache).
  bool _loaded = false;
  Future<void>? _loading;
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

  /// Display-case bios (the search map above lowercases; C9 headers
  /// render the seed's original casing).
  final Map<String, String> _designerDisplayBios = <String, String>{};

  /// Every known account (me + designers + the accounts.json community
  /// cast) — the C12 rows' display fields.
  final Map<String, ({String displayName, String? avatarUrl})> _accounts =
      <String, ({String displayName, String? avatarUrl})>{};

  /// The full follow graph as `follower→designer` edges, seed order
  /// (accounts.json `follows` — web seedFollows verbatim). The viewer's
  /// edges stay mirrored into [_follows] so every existing derivation
  /// (feed, story rail, explore morphs) reads the same state C12 mutates.
  final List<(String, String)> _graphEdges = <(String, String)>[];

  String _viewerUsername = 'kiki.adeyemi';
  String _viewerId = 'acc-kiki';
  int _commentSequence = 0;
  int _postSequence = 0;

  Future<void> _ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= () async {
      await _load();
      _loaded = true;
    }();
  }

  Future<void> _load() async {
    final now = _now();

    if (await loadSeedJson(_bundle, _meAsset) case final me?) {
      _viewerUsername = me['username'] as String? ?? _viewerUsername;
      _viewerId = me['id'] as String? ?? _viewerId;
      _accounts[_viewerUsername] = (
        displayName: me['display_name'] as String? ?? _viewerUsername,
        avatarUrl: me['avatar_url'] as String?,
      );
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
        final bio = json['bio'] as String? ?? '';
        _designerBios[username] = bio.toLowerCase();
        _designerDisplayBios[username] = bio;
        _accounts[username] = (
          displayName: json['display_name'] as String,
          avatarUrl: json['avatar_url'] as String?,
        );
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

    if (await loadSeedJson(_bundle, _accountsAsset) case final seed?) {
      for (final entry in seed['accounts'] as List<dynamic>) {
        final json = entry as Map<String, dynamic>;
        _accounts[json['username'] as String] = (
          displayName: json['display_name'] as String,
          avatarUrl: json['avatar_url'] as String?,
        );
      }
      for (final entry in seed['follows'] as List<dynamic>) {
        final edge = (entry as List<dynamic>).cast<String>();
        _graphEdges.add((edge[0], edge[1]));
        // The seed lists the viewer's own edges too — union keeps the
        // graph and the viewer set telling one story.
        if (edge[0] == _viewerUsername) _follows.add(edge[1]);
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

    await _applyPersistedEngagement();
  }

  /// The persisted engagement overlay REPLACES the seed sets it covers —
  /// an unlike of a seed-liked post must stay unliked after a restart, so
  /// a written set is the whole truth, not a union. Best-effort: the
  /// overlay is a convenience layer over the seed — a storage failure
  /// (no plugin in a bare test scope) degrades to seed defaults, never
  /// to a broken feed.
  Future<void> _applyPersistedEngagement() async {
    final persistence = _persistence;
    if (persistence == null) return;
    final ({List<String>? liked, List<String>? saved, List<String>? follows})
    overlay;
    try {
      overlay = await persistence.readFakeEngagement();
    } on Object {
      return;
    }
    if (overlay.liked case final liked?) {
      _likedPostIds
        ..clear()
        ..addAll(liked);
    }
    if (overlay.saved case final saved?) {
      _savedPostIds
        ..clear()
        ..addAll(saved);
    }
    if (overlay.follows case final follows?) {
      _follows
        ..clear()
        ..addAll(follows);
      // Re-derive the viewer's graph edges so C12 lists, profile counts
      // and the feed all read the restored truth.
      _graphEdges.removeWhere((edge) => edge.$1 == _viewerUsername);
      for (final username in follows) {
        _graphEdges.add((_viewerUsername, username));
      }
    }
  }

  /// Best-effort write-through — same degradation contract as
  /// [_applyPersistedEngagement]: a storage failure never fails the
  /// mutation it rides on.
  Future<void> _persist(
    Future<void> Function(PersistenceService persistence) write,
  ) async {
    final persistence = _persistence;
    if (persistence == null) return;
    try {
      await write(persistence);
    } on Object {
      // Seed-overlay convenience only — the in-memory truth already
      // mutated.
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
    // Followed designers PLUS the viewer's own posts: the C15 publish
    // lands at the top of the author's feed (web B5 "publish → the post
    // lands at the top of the feed"; the two-surface contract test pins
    // it). Seed posts are all designer-authored, so the union is
    // invisible until the viewer publishes.
    return <Post>[
      for (final post in _posts)
        if (_follows.contains(post.designer.username) ||
            post.designer.username == _viewerUsername)
          _view(post),
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
    maybeFailNext();
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
    maybeFailNext();
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
    await _persist((p) => p.writeFakeLikedPostIds(_likedPostIds.toList()));
    return _view(updated);
  }

  @override
  Future<Post> toggleSave(String id) async {
    await _ensureLoaded();
    maybeFailNext();
    final post = _postById(id);
    if (!_savedPostIds.add(id)) _savedPostIds.remove(id);
    await _persist((p) => p.writeFakeSavedPostIds(_savedPostIds.toList()));
    return _view(post);
  }

  @override
  Future<void> setFollow(String username, {required bool follow}) async {
    await _ensureLoaded();
    maybeFailNext();
    final edge = (_viewerUsername, username);
    if (follow) {
      _follows.add(username);
      if (!_graphEdges.contains(edge)) _graphEdges.add(edge);
    } else {
      _follows.remove(username);
      _graphEdges.remove(edge);
    }
    await _persist((p) => p.writeFakeFollows(_follows.toList()));
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
  Future<PostComment> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    await _ensureLoaded();
    maybeFailNext();
    final post = _postById(postId);
    final comment = PostComment(
      id: 'cmt-local-${++_commentSequence}',
      postId: postId,
      // The signed-in §6 test user authors composer comments.
      author: const CommentAuthor(id: 'acc-kiki', username: 'kiki.adeyemi'),
      body: body,
      createdAt: _now(),
      parentId: parentId,
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
    maybeFailNext();
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

  /// Filed reports, observable by tests (web store `reports` parity —
  /// the fake keeps them so the flow is a real mutation, not a no-op).
  final List<({String postId, ReportReason reason, String? detail})>
  filedReports = <({String postId, ReportReason reason, String? detail})>[];

  @override
  Future<void> reportPost(
    String postId,
    ReportReason reason, {
    String? detail,
  }) async {
    await _ensureLoaded();
    maybeFailNext();
    _postById(postId); // unknown post throws, web-store parity
    filedReports.add((postId: postId, reason: reason, detail: detail));
  }

  // -- profiles & social lists (C9/C12 — web store parity) ------------------

  /// Designer-status seam (recorded, fix-wave Lane A): this list and
  /// `EarningsRepositoryFake._status` both parse `designers.json`, so
  /// they agree at load — but `enableDesigner` (C13) mutates ONLY the
  /// earnings fake, and a session-enabled designer never joins this
  /// list (no posts yet, so C2/C3/C9-public render identically either
  /// way). Reconciling to one source means a cross-repository
  /// dependency the `*Remote` wave dissolves server-side — not worth
  /// building into the fakes. Compositors (profile_view_model.dart)
  /// already read designer-side truth from the earnings repository.
  bool _isDesigner(String username) =>
      _designers.any((designer) => designer.username == username);

  UserSummary _summaryOf(String username) {
    final account = _accounts[username];
    final designer = _isDesigner(username);
    final verified =
        designer &&
        _designers.firstWhere((entry) => entry.username == username).verified;
    return UserSummary(
      username: username,
      displayName: account?.displayName ?? username,
      avatarUrl: account?.avatarUrl,
      verified: verified,
      isDesigner: designer,
      viewerFollows: designer && _follows.contains(username),
    );
  }

  @override
  Future<PublicProfile> publicProfile(String username) async {
    await _ensureLoaded();
    final account = _accounts[username];
    if (account == null) throw StateError('Profile not found: $username');
    final followers = _graphEdges.where((edge) => edge.$2 == username).length;
    final following = _graphEdges.where((edge) => edge.$1 == username).length;
    if (_isDesigner(username)) {
      final designer = _designers.firstWhere(
        (entry) => entry.username == username,
      );
      return PublicProfile(
        username: username,
        displayName: designer.displayName,
        avatarUrl: designer.avatarUrl,
        bio: _designerDisplayBios[username],
        locality: designer.locality,
        isDesigner: true,
        verified: designer.verified,
        postsCount: _posts
            .where((post) => post.designer.username == username)
            .length,
        followersCount: followers,
        followingCount: following,
        viewerFollows: _follows.contains(username),
        viewerIsSelf: username == _viewerUsername,
      );
    }
    return PublicProfile(
      username: username,
      displayName: account.displayName,
      avatarUrl: account.avatarUrl,
      followersCount: followers,
      followingCount: following,
      viewerIsSelf: username == _viewerUsername,
    );
  }

  @override
  Future<List<Post>> postsBy(String username) async {
    await _ensureLoaded();
    return <Post>[
      for (final post in _posts)
        if (post.designer.username == username) _view(post),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Post>> likedPosts() async {
    await _ensureLoaded();
    return <Post>[
      for (final post in _posts)
        if (_likedPostIds.contains(post.id)) _view(post),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Post>> savedPosts() async {
    await _ensureLoaded();
    return <Post>[
      for (final post in _posts)
        if (_savedPostIds.contains(post.id)) _view(post),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<UserSummary>> followersOf(String username) async {
    await _ensureLoaded();
    return <UserSummary>[
      for (final edge in _graphEdges)
        if (edge.$2 == username) _summaryOf(edge.$1),
    ];
  }

  @override
  Future<List<UserSummary>> followingOf(String username) async {
    await _ensureLoaded();
    return <UserSummary>[
      for (final edge in _graphEdges)
        if (edge.$1 == username) _summaryOf(edge.$2),
    ];
  }

  // -- C15 composer (web store `createPost` parity) --------------------------

  @override
  Future<Post> createPost({
    required String caption,
    required List<PostMedia> media,
    String? snapshotSessionId,
  }) async {
    await _ensureLoaded();
    maybeFailNext();
    // Web-store `validation_failed` parity — the composer gates the CTA
    // on ≥1 photo, but the repository re-asserts its own invariant.
    if (media.isEmpty || media.length > 10) {
      throw StateError('Posts carry 1-10 images');
    }
    // The simulated upload beat (dev flavor sees the uploading state);
    // rides the fake timer in widget tests, zero in async unit tests.
    if (uploadDelay > Duration.zero) {
      await Future<void>.delayed(uploadDelay);
    }
    // The signed-in viewer authors composer posts. Designer gating lives
    // at the chooser (M-11) — this fake cannot see the earnings side's
    // session-enabled designer flag (the recorded designer-status seam
    // above), so it never re-gates, unlike the web store's
    // `designer_profile_required`.
    final account = _accounts[_viewerUsername];
    final post = Post(
      id: 'post-local-${++_postSequence}',
      designer: PostDesigner(
        id: _viewerId,
        username: _viewerUsername,
        displayName: account?.displayName ?? _viewerUsername,
        avatarUrl: account?.avatarUrl,
      ),
      caption: caption,
      styleTags: const <String>[],
      media: media,
      likeCount: 0,
      commentCount: 0,
      createdAt: _now(),
      snapshotSessionId: snapshotSessionId,
    );
    _posts.insert(0, post);
    return _view(post);
  }
}
