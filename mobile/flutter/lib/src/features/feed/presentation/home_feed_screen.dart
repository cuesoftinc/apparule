import 'dart:async' show unawaited;
import 'dart:math' show min;

import 'package:apparule/src/core/async/run_action.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/caught_up_divider.dart';
import 'package:apparule/src/core/ui/edge_resist_physics.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/gradient_refresh_spinner.dart';
import 'package:apparule/src/core/ui/post_card.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/ui/story_rail_item.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/data/first_save_flag.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/domain/story_rail_entry.dart';
import 'package:apparule/src/features/feed/presentation/engagement_actions.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_view_model.dart';
import 'package:apparule/src/features/feed/presentation/post_options_sheet.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// MI-6 page size — web `FEED_PAGE_SIZE` parity.
const int feedPageSize = 4;

/// The 48h freshness window shared by MI-6's caught-up boundary and
/// MI-8's story rings (design.md §4; the fake's `storyFreshWindow` reads
/// the same value from the seed side).
const Duration _freshWindow = Duration(hours: 48);

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
      // Value-preserving switch (CLASS 2): a refresh or an engagement
      // fan-out flips the AsyncValue to loading WITH the previous value —
      // the rendered feed must survive it, never swap to the skeleton
      // mid-gesture (D28).
      body: switch (state) {
        AsyncValue(:final value?) => _FeedBody(state: value),
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

class _FeedBody extends ConsumerStatefulWidget {
  const _FeedBody({required this.state});

  final HomeFeedState state;

  @override
  ConsumerState<_FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends ConsumerState<_FeedBody> {
  /// MI-6 window: how many posts the "loaded pages" cover. The repository
  /// seam stays whole-list until the API wave lands cursor pagination —
  /// the window is the honest prefetch surface over it.
  int _visible = feedPageSize;
  bool _loadingMore = false;

  void _maybePrefetch(int postIndex, int visiblePosts, int total) {
    // MI-6: prefetch at 3 cards from the end.
    if (_loadingMore || visiblePosts >= total) return;
    if (postIndex < visiblePosts - 3) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadMore());
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _visible >= widget.state.posts.length) return;
    setState(() => _loadingMore = true);
    // The pagination seam (stubbed until the API wave): one async
    // boundary, exactly where the cursor fetch will sit — the ×2 fetch
    // skeletons render across it.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() {
      _visible = min(_visible + feedPageSize, widget.state.posts.length);
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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

    final now = ref.watch(clockProvider)();
    final posts = state.posts;
    final visiblePosts = min(_visible, posts.length);
    final caughtUp = visiblePosts >= posts.length;
    // MI-6: the divider sits after the <48h-fresh block (IG pattern) —
    // everything above it is new. An all-fresh feed earns it only at the
    // end once every page is in; an all-stale feed leads with content.
    final freshCount = posts
        .where((post) => now.difference(post.createdAt) < _freshWindow)
        .length;
    final int? dividerAfter;
    if (freshCount > 0 && freshCount < posts.length) {
      dividerAfter = freshCount <= visiblePosts ? freshCount : null;
    } else {
      dividerAfter = caughtUp ? visiblePosts : null;
    }

    final storyOffset = state.stories.isNotEmpty ? 1 : 0;
    final itemCount =
        storyOffset +
        visiblePosts +
        (dividerAfter != null ? 1 : 0) +
        (_loadingMore ? 2 : 0);

    return GradientRefreshSpinner(
      // MI-5 pull-to-refresh — failure keeps the rendered list and
      // toasts (MI-18).
      onRefresh: () => runAction(
        context,
        ref.read(homeFeedViewModelProvider.notifier).refresh,
      ),
      child: ListView.builder(
        // Top-edge overscroll drives the MI-5 spinner on both platforms.
        physics: const EdgeResistPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < storyOffset) return _StoryRail(stories: state.stories);
          var postIndex = index - storyOffset;
          if (dividerAfter != null) {
            if (postIndex == dividerAfter) {
              // MI-6 — gated on the 48h freshness boundary.
              return const CaughtUpDivider();
            }
            if (postIndex > dividerAfter) postIndex -= 1;
          }
          if (postIndex < visiblePosts) {
            _maybePrefetch(postIndex, visiblePosts, posts.length);
            final post = posts[postIndex];
            return _FeedPostCard(
              // Per-post widget state (carousel slide, open caption)
              // rides the post identity, not the list position (D61).
              key: ValueKey<String>(post.id),
              post: post,
              now: now,
            );
          }
          // MI-6: skeleton ×2 during the page fetch.
          return const PostCard(
            username: '',
            media: <ImageProvider<Object>>[],
            liked: false,
            saved: false,
            likeCount: 0,
            caption: '',
            skeleton: true,
          );
        },
      ),
    );
  }
}

class _StoryRail extends ConsumerWidget {
  const _StoryRail({required this.stories});

  final List<StoryRailEntry> stories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Semantics(
      container: true,
      label: l10n.feedStoriesLabel,
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: stories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final story = stories[index];
            return StoryRailItem(
              username: story.username,
              image: seedMediaImageOrNull(story.avatarUrl),
              state: story.unseen
                  ? StoryRailItemState.unseen
                  : StoryRailItemState.seen,
              // Opens the designer's C9 profile (web FeedView parity:
              // the rail item links `/dashboard/{username}`), consuming
              // the ring on the way.
              onTap: () => unawaited(_openStory(context, ref, story)),
            );
          },
        ),
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
      await PublicProfileRoute(username: story.username).push<void>(context);
    }
  }
}

class _FeedPostCard extends ConsumerWidget {
  const _FeedPostCard({required this.post, required this.now, super.key});

  final Post post;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      // Engagement routes through the façade (CLASS 1) inside runAction
      // (CLASS 4) — a failed toggle toasts and every surface stays at
      // the old truth.
      onToggleLike: () => unawaited(
        runAction(
          context,
          () => ref
              .read(engagementActionsProvider.notifier)
              .toggleLike(post.id),
        ),
      ),
      onToggleSave: () => unawaited(toggleSaveWithFirstSaveToast(
        context,
        ref,
        postId: post.id,
        wasSaved: post.saved,
      )),
      onComment: () => PostCommentsRoute(id: post.id).push<void>(context),
      onShare: () => unawaited(sharePostLink(context, post.id)),
      onOverflow: () =>
          unawaited(showPostOptionsSheet(context, postId: post.id)),
      onRequest: () => RequestRoute(postId: post.id).push<void>(context),
      onProfileTap: () => PublicProfileRoute(
        username: post.designer.username,
      ).push<void>(context),
    );
  }
}

/// The MI-3 save path shared by C2 and C4: the toggle through the façade
/// inside `runAction`, then — on a SUCCESSFUL first-ever save — the
/// "Saved to your looks" toast (a failed save must never claim one).
Future<void> toggleSaveWithFirstSaveToast(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
  required bool wasSaved,
}) async {
  final ok = await runAction(
    context,
    () => ref.read(engagementActionsProvider.notifier).toggleSave(postId),
  );
  if (ok && context.mounted) {
    await maybeShowFirstSaveToast(context, ref, wasSaved: wasSaved);
  }
}

/// MI-3: the first-ever save shows "Saved to your looks" with a View
/// action into the profile's saved looks (web `FeedView`/`first-save.ts`
/// parity — once per install, gated behind the persisted flag).
Future<void> maybeShowFirstSaveToast(
  BuildContext context,
  WidgetRef ref, {
  required bool wasSaved,
}) async {
  // Pre-toggle saved means this tap UN-saved — no toast (web parity).
  if (wasSaved) return;
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final router = GoRouter.of(context);
  final claimed = await ref.read(firstSaveFlagProvider.notifier).claim();
  if (!claimed) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.feedFirstSaveToast),
      action: SnackBarAction(
        label: l10n.feedFirstSaveView,
        onPressed: () => router.go(const ProfileRoute().location),
      ),
    ),
  );
}

/// MI-9 share: the public permalink (web-implementation.md §4
/// `/p/{post_id}`) through the platform share sheet (the mobile MI-9
/// idiom — D30). Environments without one (widget tests, desktop hosts)
/// degrade to the clipboard-copy idiom with its confirmation snack.
Future<void> sharePostLink(BuildContext context, String postId) async {
  final messenger = ScaffoldMessenger.of(context);
  final copied = context.l10n.feedShareCopied;
  final url = postPermalink(postId);
  try {
    await SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
  } on Object {
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(SnackBar(content: Text(copied)));
  }
}
