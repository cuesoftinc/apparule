import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/comment.dart';
import 'package:apparule/src/features/feed/presentation/comments_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C11 — the comments sheet at full height (pages.md [Directive
/// 2026-07-18]): CommentRow list with like hearts, composer pinned above
/// the keyboard, optimistic post (MI-18). Rendered as a transparent
/// route over C4 (routes.dart), so the post dims beneath the sheet.
class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _composer.text;
    _composer.clear();
    await ref
        .read(commentsViewModelProvider(widget.postId).notifier)
        .addComment(body);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final state = ref.watch(commentsViewModelProvider(widget.postId));
    final comments = state.value ?? const <PostComment>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        // The sheet fills 88% — the dimmed post peeks above (canvas).
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 12,
              child: GestureDetector(
                // Tapping the exposed post scrim closes the sheet.
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              flex: 88,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radii.card),
                ),
                child: ColoredBox(
                  color: colors.bgElev,
                  child: Column(
                    children: <Widget>[
                      // Grabber + centred title + close (Sheet anatomy).
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: <Widget>[
                            const SizedBox(width: 36, height: 36),
                            Expanded(
                              child: Text(
                                l10n.commentsTitle(comments.length),
                                textAlign: TextAlign.center,
                                style: typography.body16SemiBold.copyWith(
                                  color: colors.text,
                                ),
                              ),
                            ),
                            Semantics(
                              label: 'Close',
                              button: true,
                              child: InkResponse(
                                onTap: () => Navigator.of(context).pop(),
                                radius: 18,
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(
                                    LucideIcons.x,
                                    size: 24,
                                    color: colors.text,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: switch (state) {
                          AsyncError(:final error) => Center(
                            child: Text('$error'),
                          ),
                          AsyncLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          _ => ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: comments.length,
                            itemBuilder: (context, index) => _CommentRow(
                              comment: comments[index],
                              postId: widget.postId,
                            ),
                          ),
                        },
                      ),
                      // Composer pinned above the keyboard (MI-18).
                      Container(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 8,
                          top: 8,
                          bottom: 8 + MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: colors.border),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _composer,
                                onSubmitted: (_) => _send(),
                                textInputAction: TextInputAction.send,
                                style: typography.body14.copyWith(
                                  color: colors.text,
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.postAddComment,
                                  hintStyle: typography.body14.copyWith(
                                    color: colors.text2,
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: colors.bg,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      radii.card,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      radii.card,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Semantics(
                              label: l10n.commentsSendLabel,
                              button: true,
                              child: InkResponse(
                                onTap: _send,
                                radius: 22,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    LucideIcons.send,
                                    size: 22,
                                    color: colors.text,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentRow extends ConsumerWidget {
  const _CommentRow({required this.comment, required this.postId});

  final PostComment comment;
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Avatar(
            name: comment.author.username,
            size: AvatarSize.s32,
            image: seedMediaImageOrNull(comment.author.avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: '${comment.author.username} ',
                        style: typography.body14.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      TextSpan(text: comment.body),
                    ],
                  ),
                  style: typography.body14.copyWith(color: colors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  <String>[
                    formatAgo(
                      comment.createdAt,
                      now: ref.watch(clockProvider)(),
                    ),
                    if (comment.likeCount > 0)
                      l10n.commentsLikeCount(comment.likeCount),
                    l10n.commentsReply,
                  ].join('   '),
                  style: typography.micro12.copyWith(color: colors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: comment.liked
                ? l10n.commentsUnlikeLabel
                : l10n.commentsLikeLabel,
            button: true,
            toggled: comment.liked,
            child: InkResponse(
              onTap: () => ref
                  .read(commentsViewModelProvider(postId).notifier)
                  .toggleCommentLike(comment.id),
              radius: 18,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  comment.liked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: comment.liked ? colors.like : colors.text2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
