import 'package:apparule/src/features/feed/domain/comment.dart';
import 'package:apparule/src/features/feed/domain/explore_results.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/domain/public_profile.dart';
import 'package:apparule/src/features/feed/domain/report_reason.dart';
import 'package:apparule/src/features/feed/domain/story_rail_entry.dart';
import 'package:apparule/src/features/feed/domain/user_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_repository.g.dart';

/// Abstract post/social-graph repository — C2/C3/C4/C11 all operate over
/// this one domain (mobile-implementation.md §3). Engagement calls are
/// real state mutations (like counts move, the follow graph re-derives
/// the feed) — the web mock store's semantics, not static JSON rendering.
abstract class PostRepository {
  /// The home-feed posts (C2): followed designers only, newest first
  /// (web store `feed()` parity).
  Future<List<Post>> homeFeed();

  /// The C2 story rail (MI-8): followed designers with published work,
  /// ring lit while they have <48h posts the viewer hasn't opened
  /// (web `storyDesignersOf` parity).
  Future<List<StoryRailEntry>> storyRail();

  /// Opening a story dims its ring until the designer posts again.
  Future<void> markStorySeen(String username);

  /// C3 explore: the recency-ordered browse grid, sectioned search
  /// results when [query] is non-empty, an optional [tag] chip filter,
  /// and the near-me proximity RE-RANKING — city > state > country
  /// tiers, never a hard gate (pages.md B2 [Revised 2026-07-19]).
  Future<ExploreResults> explore({String query, String? tag, bool nearMe});

  /// One post by id (C4).
  Future<Post> post(String id);

  /// MI-1/MI-2 like toggle — mutates the like set + count, returns the
  /// updated post.
  Future<Post> toggleLike(String id);

  /// MI-3 save toggle.
  Future<Post> toggleSave(String id);

  /// MI-7 follow morph — feed and story rail re-derive from the graph.
  Future<void> setFollow(String username, {required bool follow});

  /// A post's visible comments, oldest first (C11).
  Future<List<PostComment>> comments(String postId);

  /// MI-18 composer — appends and bumps the post's comment count (the
  /// web store's unit-gated count==list invariant). [parentId] marks the
  /// row a reply to an existing comment (C11 reply-indent).
  Future<PostComment> addComment(
    String postId,
    String body, {
    String? parentId,
  });

  /// C11 comment heart toggle.
  Future<PostComment> toggleCommentLike(String commentId);

  /// SOC-009 moderation report on a post (web store `fileReport('post',…)`
  /// parity) — the PostCard ⋯ overflow's report flow.
  Future<void> reportPost(
    String postId,
    ReportReason reason, {
    String? detail,
  });

  /// The C9 `/profile/{username}` header — counts derive from the same
  /// follow graph the feed re-derives from (the web store's P1 realism
  /// invariant: the header and the followers sheet never disagree).
  Future<PublicProfile> publicProfile(String username);

  /// A designer's published grid, newest first (C9 other; web `postsBy`).
  Future<List<Post>> postsBy(String username);

  /// The viewer's liked grid (C9 own — the non-designer's first tab).
  Future<List<Post>> likedPosts();

  /// The viewer's saved grid — viewer-private (pages.md B6 [Decided
  /// 2026-07-20]; web `savedPosts`).
  Future<List<Post>> savedPosts();

  /// Accounts following [username], seed-graph order (C12; web
  /// `followersOf`). Empty for non-designers — nothing throws, so C12
  /// renders its empty copy instead of an error state.
  Future<List<UserSummary>> followersOf(String username);

  /// Designers [username] follows (C12; web `followingOf`).
  Future<List<UserSummary>> followingOf(String username);
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) => throw UnimplementedError(
  'postRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
