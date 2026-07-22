import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/comment.dart';
import 'package:apparule/src/features/feed/presentation/post_detail_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments_view_model.g.dart';

/// C11's ViewModel — a post's comments; posting appends through the
/// repository (which keeps count == list, the web store invariant) and
/// refreshes the C4 state beneath the sheet.
@riverpod
class CommentsViewModel extends _$CommentsViewModel {
  @override
  Future<List<PostComment>> build(String postId) =>
      ref.watch(postRepositoryProvider).comments(postId);

  /// MI-18 composer post — the fake answers instantly, so the appended
  /// row IS the optimistic echo.
  Future<void> addComment(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final comment = await ref
        .read(postRepositoryProvider)
        .addComment(postId, trimmed);
    if (state.value case final current?) {
      state = AsyncData(<PostComment>[...current, comment]);
    }
    // The C4 "View all N comments" count beneath the sheet re-derives.
    ref.invalidate(postDetailViewModelProvider(postId));
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
