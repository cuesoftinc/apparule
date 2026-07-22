import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_view_model.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_view_model.dart';
import 'package:apparule/src/features/profile/presentation/unfollow_confirm_sheet.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C9 — designer public profile (canvas 267:8539; pages.md B6): story-
/// ring avatar, graph-derived counts (followers/following open C12),
/// bio, the MI-7 Follow morph (gradient ⇄ quiet with the unfollow
/// confirm) beside the quiet "Request an outfit" CTA (→ C5 over the
/// newest post — never a blank compose), and the published grid alone —
/// saved is viewer-private, so other viewers never see tabs
/// ([Decided 2026-07-20]). Regular users render the private-vault
/// variant instead.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(publicProfileViewModelProvider(username));

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: username,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const HomeRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value) => _PublicProfileBody(state: value),
        AsyncError() => Center(child: Text(l10n.profileNotFound(username))),
        _ => ListView(
          padding: const EdgeInsets.all(16),
          children: const <Widget>[
            Row(
              children: <Widget>[
                Skeleton(kind: SkeletonKind.avatar),
                SizedBox(width: 16),
                Expanded(child: Skeleton()),
              ],
            ),
            SizedBox(height: 16),
            Skeleton(kind: SkeletonKind.card),
          ],
        ),
      },
    );
  }
}

class _PublicProfileBody extends ConsumerWidget {
  const _PublicProfileBody({required this.state});

  final PublicProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final profile = state.profile;

    Future<void> toggleFollow() async {
      final controller = ref.read(followGraphControllerProvider.notifier);
      if (profile.viewerFollows) {
        // MI-7: unfollow is never a blind toggle.
        final confirmed = await showUnfollowConfirmSheet(
          context,
          username: profile.username,
          image: seedMediaImageOrNull(profile.avatarUrl),
        );
        if (confirmed) {
          await controller.setFollow(profile.username, follow: false);
        }
      } else {
        await controller.setFollow(profile.username, follow: true);
      }
    }

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                Avatar(
                  name: profile.displayName,
                  image: seedMediaImageOrNull(profile.avatarUrl),
                  size: AvatarSize.s96,
                  // B6: designer headers carry the story-ring
                  // construction; regular users render plain (MI-11 —
                  // rings mean vault only on one's OWN header).
                  ring: profile.isDesigner
                      ? AvatarRing.gradient
                      : AvatarRing.none,
                  badge: profile.verified
                      ? AvatarBadge.designerVerified
                      : AvatarBadge.none,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Expanded(
                        child: _StatColumn(
                          value: profile.postsCount,
                          label: l10n.profilePosts,
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          value: profile.followersCount,
                          label: l10n.profileFollowers,
                          onTap: () => FollowersRoute(
                            username: profile.username,
                          ).push<void>(context),
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          value: profile.followingCount,
                          label: l10n.profileFollowingLabel,
                          onTap: () => FollowingRoute(
                            username: profile.username,
                          ).push<void>(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (profile.isDesigner)
                  Text(
                    <String?>[
                      profile.displayName,
                      profile.locality,
                    ].whereType<String>().join(' · '),
                    style: typography.body16SemiBold.copyWith(
                      color: colors.text,
                    ),
                  )
                else
                  Text(
                    profile.displayName,
                    style: typography.body16SemiBold.copyWith(
                      color: colors.text,
                    ),
                  ),
                if (profile.bio case final bio?) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    bio,
                    style: typography.body14.copyWith(color: colors.text),
                  ),
                ],
                if (!profile.isDesigner) ...<Widget>[
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(LucideIcons.lock, size: 12, color: colors.text2),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.profileMeasurementsPrivate,
                          style: typography.caption13.copyWith(
                            color: colors.text2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (profile.isDesigner && !profile.viewerIsSelf)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: <Widget>[
                  // Canvas 267:8539: Follow carries the gradient; the
                  // Request CTA is quiet.
                  Expanded(
                    child: Button(
                      label: profile.viewerFollows
                          ? l10n.exploreFollowing
                          : l10n.exploreFollow,
                      kind: profile.viewerFollows
                          ? ButtonKind.quiet
                          : ButtonKind.gradientPrimary,
                      expand: true,
                      onPressed: toggleFollow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Button(
                      label: l10n.profileRequestOutfit,
                      kind: ButtonKind.quiet,
                      expand: true,
                      onPressed: state.posts.isEmpty
                          ? null
                          : () => RequestRoute(
                              postId: state.posts.first.id,
                            ).push<void>(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (profile.isDesigner)
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: state.posts.length,
                (context, index) => _GridTile(post: state.posts[index]),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    final column = Column(
      children: <Widget>[
        Text(
          formatCount(value),
          style: typography.body16SemiBold.copyWith(
            color: colors.text,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
      ],
    );
    if (onTap == null) return column;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: column,
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      button: true,
      label: post.media.first.altText,
      child: GestureDetector(
        onTap: () => PostDetailRoute(id: post.id).push<void>(context),
        child: ColoredBox(
          color: colors.border.withValues(alpha: 0.3),
          child: Image(
            image: seedMediaImage(post.media.first.url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
