import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';

/// A comment author summary (web `Comment.author` parity).
@freezed
abstract class CommentAuthor with _$CommentAuthor {
  const factory CommentAuthor({
    required String id,
    required String username,
    String? avatarUrl,
  }) = _CommentAuthor;
}

/// One post comment (data-model.md §5 COMMENT; web mock seed parity).
@freezed
abstract class PostComment with _$PostComment {
  const factory PostComment({
    required String id,
    required String postId,
    required CommentAuthor author,
    required String body,
    required DateTime createdAt,
    @Default(0) int likeCount,

    /// Viewer-scoped comment like (C11 heart).
    @Default(false) bool liked,
  }) = _PostComment;
}
