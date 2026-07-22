import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/caught_up_divider.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/post_card.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/ui/story_rail_item.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/domain/story_rail_entry.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C2 — the home feed (pages.md: = B1 minus the right column): story rail
/// over the PostCard column, MI-1/2/3/4/5/6 active, all interactions
/// mutating the seeded fake state.
class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(homeFeedViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n.appTitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _TopBarIcon(
              icon: LucideIcons.bell,
              label: l10n.feedNotificationsLabel,
              onTap: () => const NotificationsRoute().push<void>(context),
            ),
            // Order threads are the only messaging surface in v1
            // (SOC-010: full DMs are Later) — the send affordance lands
            // on the Orders tab.
            _TopBarIcon(
              icon: LucideIcons.send,
              label: l10n.feedMessagesLabel,
              onTap: () => const OrdersRoute().go(context),
            ),
          ],
        ),
      ),
      body: switch (state) {
        AsyncData(:final value) => _FeedBody(state: value),
        AsyncError() => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: EmptyState(
              kind: EmptyStateKind.feed,
              line: l10n.feedErrorLine,
              ctaLabel: l10n.feedRetry,
              onCta: () => ref.invalidate(homeFeedViewModelProvider),
            ),
          ),
        ),
        _ => const _FeedSkeleton(),
      },
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

/// The C2-feed-loading frame: story-circle rail over PostCard skeletons.
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Skeleton(kind: SkeletonKind.avatar),
              SizedBox(width: 16),
              Skeleton(kind: SkeletonKind.avatar),
              SizedBox(width: 16),
              Skeleton(kind: SkeletonKind.avatar),
              SizedBox(width: 16),
              Skeleton(kind: SkeletonKind.avatar),
              SizedBox(width: 16),
              Skeleton(kind: SkeletonKind.avatar),
            ],
          ),
        ),
        PostCard(
          username: '',
          media: <ImageProvider<Object>>[],
          liked: false,
          saved: false,
          likeCount: 0,
          caption: '',
          skeleton: true,
        ),
        PostCard(
          username: '',
          media: <ImageProvider<Object>>[],
          liked: false,
          saved: false,
          likeCount: 0,
          caption: '',
          skeleton: true,
        ),
      ],
    );
  }
}

class _FeedBody extends ConsumerWidget {
  const _FeedBody({required this.state});

  final HomeFeedState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (state.posts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            kind: EmptyStateKind.feed,
            onCta: () => const ExploreRoute().go(context),
          ),
        ),
      );
    }

    final viewModel = ref.read(homeFeedViewModelProvider.notifier);
    return RefreshIndicator(
      // MI-5 pull-to-refresh.
      onRefresh: viewModel.refresh,
      child: ListView(
        children: <Widget>[
          if (state.stories.isNotEmpty)
            Semantics(
              container: true,
              label: l10n.feedStoriesLabel,
              child: SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: state.stories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final story = state.stories[index];
                    return StoryRailItem(
                      username: story.username,
                      image: seedMediaImageOrNull(story.avatarUrl),
                      state: story.unseen
                          ? StoryRailItemState.unseen
                          : StoryRailItemState.seen,
                      // Opens the designer's newest outfit (their C9
                      // profile takes over once the profile wave lands).
                      onTap: () => _openStory(context, ref, story),
                    );
                  },
                ),
              ),
            ),
          for (final post in state.posts)
            _FeedPostCard(
              post: post,
              viewModel: viewModel,
              now: ref.watch(clockProvider)(),
            ),
          // MI-6 — the feed ends at seeded content older than the rail's
          // freshness window.
          const CaughtUpDivider(),
        ],
      ),
    );
  }

  Future<void> _openStory(
    BuildContext context,
    WidgetRef ref,
    StoryRailEntry story,
  ) async {
    await ref
        .read(homeFeedViewModelProvider.notifier)
        .markStorySeen(story.username);
    if (context.mounted) {
      await PostDetailRoute(id: story.newestPostId).push<void>(context);
    }
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.post,
    required this.viewModel,
    required this.now,
  });

  final Post post;
  final HomeFeedViewModel viewModel;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return PostCard(
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
      timestampLabel: formatAgo(post.createdAt, now: now),
      onToggleLike: () => viewModel.toggleLike(post.id),
      onToggleSave: () => viewModel.toggleSave(post.id),
      onComment: () => PostCommentsRoute(id: post.id).push<void>(context),
      onShare: () => sharePostLink(context, post.id),
      onRequest: () => RequestRoute(postId: post.id).push<void>(context),
    );
  }
}

/// MI-9 share: the public permalink (web-implementation.md §4
/// `/p/{post_id}`) lands on the clipboard with a confirmation snack.
Future<void> sharePostLink(BuildContext context, String postId) async {
  final messenger = ScaffoldMessenger.of(context);
  final copied = context.l10n.feedShareCopied;
  await Clipboard.setData(
    ClipboardData(text: 'https://apparule.cuesoft.io/p/$postId'),
  );
  messenger.showSnackBar(SnackBar(content: Text(copied)));
}
