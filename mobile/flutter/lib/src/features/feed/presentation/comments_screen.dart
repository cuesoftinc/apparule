import 'dart:async';

import 'package:apparule/src/core/async/run_action.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/action_row.dart' show LucideHeart;
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/comment.dart';
import 'package:apparule/src/features/feed/presentation/comments_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C11 — the comments sheet at full height (pages.md [Directive
/// 2026-07-18]): CommentRow list with like hearts and reply-indent,
/// composer pinned above the keyboard, optimistic post (MI-18).
/// Rendered as a transparent route over C4 (routes.dart), so the post
/// dims beneath the sheet; the grabber drags to dismiss (D37).
class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocus = FocusNode();

  /// Armed reply target (D27): the composer posts under this parent.
  PostComment? _replyTo;

  /// Grabber drag offset — the sheet follows the finger down (D37).
  double _dragOffset = 0;

  @override
  void dispose() {
    _composer.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_composer.text.trim().isEmpty) return;
    final body = _composer.text;
    // Replies to replies thread under the top-level parent (one indent
    // level, the IG idiom the web CommentRow mirrors).
    final parentId = _replyTo?.parentId ?? _replyTo?.id;
    // CLASS 4: the composer clears ONLY after a successful post — a
    // failed send toasts and the user's text stays put.
    final ok = await runAction(
      context,
      () => ref
          .read(commentsViewModelProvider(widget.postId).notifier)
          .addComment(body, parentId: parentId),
    );
    if (!ok || !mounted) return;
    _composer.clear();
    setState(() => _replyTo = null);
  }

  /// D27: Reply prefills the composer with the author handle and arms
  /// the parent target.
  void _armReply(PostComment comment) {
    setState(() => _replyTo = comment);
    _composer.text = '@${comment.author.username} ';
    _composer.selection = TextSelection.collapsed(
      offset: _composer.text.length,
    );
    _composerFocus.requestFocus();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0, double.infinity);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > 120 || velocity > 700) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  /// Threads the flat list: top-level rows oldest-first, each followed
  /// by its replies oldest-first (reply-indent, D27).
  List<PostComment> _threaded(List<PostComment> comments) {
    final topLevel = <PostComment>[
      for (final comment in comments)
        if (comment.parentId == null) comment,
    ];
    final byParent = <String, List<PostComment>>{};
    for (final comment in comments) {
      if (comment.parentId case final parent?) {
        byParent.putIfAbsent(parent, () => <PostComment>[]).add(comment);
      }
    }
    return <PostComment>[
      for (final parent in topLevel) ...<PostComment>[
        parent,
        ...byParent[parent.id] ?? const <PostComment>[],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final state = ref.watch(commentsViewModelProvider(widget.postId));
    final comments = _threaded(state.value ?? const <PostComment>[]);

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
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radii.card),
                  ),
                  child: ColoredBox(
                    color: colors.bgElev,
                    child: Column(
                      children: <Widget>[
                        // Grabber + centred title + close (Sheet
                        // anatomy); the zone drags to dismiss (D37).
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: _handleDragUpdate,
                          onVerticalDragEnd: _handleDragEnd,
                          child: Column(
                            children: <Widget>[
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
                                        style: typography.body16SemiBold
                                            .copyWith(color: colors.text),
                                      ),
                                    ),
                                    Semantics(
                                      label: 'Close',
                                      button: true,
                                      child: InkResponse(
                                        onTap: () =>
                                            Navigator.of(context).pop(),
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
                            ],
                          ),
                        ),
                        Expanded(
                          // Value-preserving switch (CLASS 2): posting
                          // re-derives siblings, never this list — but a
                          // refresh must keep rendered rows regardless.
                          child: switch (state) {
                            AsyncValue(hasValue: true) => ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              itemCount: comments.length,
                              itemBuilder: (context, index) => _CommentRow(
                                key: ValueKey<String>(comments[index].id),
                                comment: comments[index],
                                postId: widget.postId,
                                onReply: _armReply,
                              ),
                            ),
                            AsyncError(:final error) => Center(
                              child: Text('$error'),
                            ),
                            _ => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          },
                        ),
                        // Replying-to chip — cancel disarms (D27).
                        if (_replyTo case final replyTo?)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            color: colors.bg,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    l10n.commentsReplyingTo(
                                      replyTo.author.username,
                                    ),
                                    style: typography.caption13.copyWith(
                                      color: colors.text2,
                                    ),
                                  ),
                                ),
                                Semantics(
                                  label: l10n.commentsCancelReply,
                                  button: true,
                                  child: InkResponse(
                                    onTap: () =>
                                        setState(() => _replyTo = null),
                                    radius: 14,
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Icon(
                                        LucideIcons.x,
                                        size: 16,
                                        color: colors.text2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Composer pinned above the keyboard (MI-18).
                        Container(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 8,
                            top: 8,
                            bottom:
                                8 + MediaQuery.viewInsetsOf(context).bottom,
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
                                  focusNode: _composerFocus,
                                  onSubmitted: (_) => unawaited(_send()),
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
                                    contentPadding:
                                        const EdgeInsets.symmetric(
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
                                  onTap: () => unawaited(_send()),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentRow extends ConsumerStatefulWidget {
  const _CommentRow({
    required this.comment,
    required this.postId,
    required this.onReply,
    super.key,
  });

  final PostComment comment;
  final String postId;
  final ValueChanged<PostComment> onReply;

  @override
  ConsumerState<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends ConsumerState<_CommentRow> {
  // Owned here (not build-scoped) so the arena entry is disposed.
  final TapGestureRecognizer _authorRecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _authorRecognizer.onTap = _openAuthorProfile;
  }

  @override
  void dispose() {
    _authorRecognizer.dispose();
    super.dispose();
  }

  /// Commenter avatar/name → the author's C9 profile (live-QA sweep:
  /// every entity reference navigates to its entity screen).
  void _openAuthorProfile() {
    unawaited(
      PublicProfileRoute(
        username: widget.comment.author.username,
      ).push<void>(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final comment = widget.comment;
    // Reply-indent (D27): replies nest one avatar column deep.
    final indent = comment.parentId != null ? 44.0 : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16 + indent, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            // One node (the StoryRailItem pattern) — the avatar's own
            // name semantics fold into the affordance announcement.
            container: true,
            excludeSemantics: true,
            label: 'View ${comment.author.username} profile',
            button: true,
            onTap: _openAuthorProfile,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openAuthorProfile,
              child: Avatar(
                name: comment.author.username,
                size: AvatarSize.s32,
                image: seedMediaImageOrNull(comment.author.avatarUrl),
              ),
            ),
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
                        recognizer: _authorRecognizer,
                        semanticsLabel:
                            'View ${comment.author.username} profile',
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
                Row(
                  children: <Widget>[
                    Text(
                      <String>[
                        formatAgo(
                          comment.createdAt,
                          now: ref.watch(clockProvider)(),
                        ),
                        if (comment.likeCount > 0)
                          l10n.commentsLikeCount(comment.likeCount),
                      ].join('   '),
                      style: typography.micro12.copyWith(color: colors.text2),
                    ),
                    const SizedBox(width: 12),
                    // A real reply affordance (D27) — prefills the
                    // composer and arms the parent target.
                    Semantics(
                      label: l10n.commentsReplyLabel(comment.author.username),
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onReply(comment),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            l10n.commentsReply,
                            style: typography.micro12.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.text2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
              // CLASS 4: a failed heart rolls back at the repository and
              // toasts.
              onTap: () => unawaited(
                runAction(
                  context,
                  () => ref
                      .read(commentsViewModelProvider(widget.postId).notifier)
                      .toggleCommentLike(comment.id),
                ),
              ),
              radius: 18,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  // The DS Lucide heart fill idiom (D60) — Material's
                  // favorite glyph is off-catalog.
                  child: LucideHeart(
                    color: comment.liked ? colors.like : colors.text2,
                    filled: comment.liked,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
