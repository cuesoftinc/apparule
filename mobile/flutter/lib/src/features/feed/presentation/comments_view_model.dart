import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/comment.dart';
import 'package:apparule/src/features/feed/presentation/engagement_actions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments_view_model.g.dart';

/// C11's ViewModel — a post's comments; posting appends through the
/// `EngagementActions` façade (which keeps count == list at the
/// repository and fans out to C2/C4/C9 — D33), echoing the returned row
/// locally so the sheet never refetches under the composer.
@riverpod
class CommentsViewModel extends _$CommentsViewModel {
  @override
  Future<List<PostComment>> build(String postId) =>
      ref.watch(postRepositoryProvider).comments(postId);

  /// MI-18 composer post — the fake answers instantly, so the appended
  /// row IS the optimistic echo.
  Future<void> addComment(String body, {String? parentId}) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final comment = await ref
        .read(engagementActionsProvider.notifier)
        .addComment(postId, trimmed, parentId: parentId);
    if (state.value case final current?) {
      state = AsyncData(<PostComment>[...current, comment]);
    }
  }

  Future<void> toggleCommentLike(String commentId) async {
    final updated = await ref
        .read(postRepositoryProvider)
        .toggleCommentLike(commentId);
    if (state.value case final current?) {
      state = AsyncData(<PostComment>[
        for (final comment in current)
          comment.id == updated.id ? updated : comment,
      ]);
    }
  }
}
