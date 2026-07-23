import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';

/// The designer summary a post carries (web `Post.designer` parity).
@freezed
abstract class PostDesigner with _$PostDesigner {
  const factory PostDesigner({
    required String id,
    required String username,
    required String displayName,

    /// Seed-relative media URL (`/demo/...`) — resolved to an image
    /// provider by `seedMediaImage` (core/utils); `null` renders initials.
    String? avatarUrl,
    @Default(false) bool verified,
  }) = _PostDesigner;
}

/// One media page of a post (web `MediaItem` parity, trimmed to what the
/// mobile surfaces render).
@freezed
abstract class PostMedia with _$PostMedia {
  const factory PostMedia({
    required String url,
    required String altText,
  }) = _PostMedia;
}

/// A published outfit post (data-model.md §5 POST; web mock seed parity —
/// same ids/captions/counts as `web/src/mocks/seed.ts`).
@freezed
abstract class Post with _$Post {
  const factory Post({
    required String id,
    required PostDesigner designer,
    required String caption,
    required List<String> styleTags,
    required List<PostMedia> media,
    required int likeCount,
    required int commentCount,
    required DateTime createdAt,

    /// Base price in kobo; `null` = "quote on request".
    int? basePriceCents,
    @Default('NGN') String currency,
    @Default(0) int turnaroundDays,

    /// Viewer-scoped engagement (web `viewPost` parity).
    @Default(false) bool liked,
    @Default(false) bool saved,

    /// The measurement-snapshot ref a C15 composer post carries when the
    /// attach toggle is ON (M-11: posts carry the fit data this look was
    /// tailored for) — the vault session's id at publish time. Seed
    /// posts and snapshot-less publishes carry `null`.
    String? snapshotSessionId,
  }) = _Post;
}
