import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/comment.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_view_model.dart';
import 'package:apparule/src/features/feed/presentation/post_detail_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'engagement_actions.g.dart';

/// The engagement mutation façade (the interaction audit's CLASS 1 lock):
/// every like/save/comment mutation routes through here, and ONLY here —
/// `ref.invalidate` on engagement surfaces outside this façade is banned.
///
/// DECLARED invalidation fan-out — like/save/comment ⇒
///   · [homeFeedViewModelProvider] (C2 feed + rail),
///   · [postDetailViewModelProvider] for the mutated post (C4),
///   · [profileViewModelProvider] (C9 liked/saved grids).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// Rationale: the shell keeps every branch mounted and Riverpod 3 pauses
/// (never disposes) their subscriptions, so a mutation that invalidates
/// only its own provider leaves sibling tabs stale for the whole session
/// (D01/D33 — the "works in tests, broken on device" class). keepAlive
/// for the ratified orchestration reason: a read-only controller must
/// not unmount its Ref across the repository await.
@Riverpod(keepAlive: true)
class EngagementActions extends _$EngagementActions {
  @override
  void build() {}

  /// MI-1/MI-2 like toggle — returns the updated post for the caller's
  /// local echo; every declared surface re-derives.
  Future<Post> toggleLike(String postId) async {
    final updated = await ref.read(postRepositoryProvider).toggleLike(postId);
    _fanOut(postId);
    return updated;
  }

  /// MI-3 save toggle.
  Future<Post> toggleSave(String postId) async {
    final updated = await ref.read(postRepositoryProvider).toggleSave(postId);
    _fanOut(postId);
    return updated;
  }

  /// MI-18 comment post — the count echoes into C2's "View all N
  /// comments" and C4 beneath the sheet (D33). [parentId] threads a
  /// reply under its parent row (C11 reply-indent, D27).
  Future<PostComment> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    final comment = await ref
        .read(postRepositoryProvider)
        .addComment(postId, body, parentId: parentId);
    _fanOut(postId);
    return comment;
  }

  void _fanOut(String postId) {
    ref
      ..invalidate(homeFeedViewModelProvider)
      ..invalidate(postDetailViewModelProvider(postId))
      ..invalidate(profileViewModelProvider);
  }
}
