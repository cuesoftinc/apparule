import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/post_card.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:apparule/src/features/feed/presentation/post_detail_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C4 — post detail (pages.md: full-bleed carousel · action row ·
/// caption · comments entry · Request CTA pinned bottom, safe-area).
/// The PostCard module renders the shared anatomy; the pinned CTA hands
/// off to C5 with this post's designer and pricing context.
class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(postDetailViewModelProvider(postId));

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.postDetailTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            // Deep-linked (`/p/{post_id}` app link) with an empty stack.
            const HomeRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value) => _PostDetailBody(post: value),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PostDetailBody extends ConsumerWidget {
  const _PostDetailBody({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final viewModel = ref.read(postDetailViewModelProvider(post.id).notifier);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            children: <Widget>[
              PostCard(
                username: post.designer.username,
                avatarImage: seedMediaImageOrNull(post.designer.avatarUrl),
                verified: post.designer.verified,
                media: <ImageProvider<Object>>[
                  for (final media in post.media) seedMediaImage(media.url),
                ],
                liked: post.liked,
                saved: post.saved,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                caption: post.caption,
                timestampLabel: formatAgo(
                  post.createdAt,
                  now: ref.watch(clockProvider)(),
                ),
                onToggleLike: viewModel.toggleLike,
                onToggleSave: viewModel.toggleSave,
                onComment: () =>
                    PostCommentsRoute(id: post.id).push<void>(context),
                onShare: () => sharePostLink(context, post.id),
                onProfileTap: () => PublicProfileRoute(
                  username: post.designer.username,
                ).push<void>(context),
              ),
              // The composer affordance — tapping opens the C11 sheet
              // with the keyboard-ready composer.
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () =>
                      PostCommentsRoute(id: post.id).push<void>(context),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: colors.bgElev,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(radii.card),
                    ),
                    child: Text(
                      l10n.postAddComment,
                      style: typography.body14.copyWith(color: colors.text2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Request CTA pinned bottom (safe-area) → the C5 stepper.
        Container(
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Button(
                label: l10n.postRequestCta,
                expand: true,
                onPressed: () =>
                    RequestRoute(postId: post.id).push<void>(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
