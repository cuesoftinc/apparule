import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/ui/tabs.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C9 — own profile (Profile tab; canvas 174:964): the MI-11
/// vault-freshness ring header (THE C7 entry, pages.md C7), social
/// counts off the same graph the feed derives from, Edit profile +
/// Measurement vault quiet pair, and the grid/saved icon tabs — a
/// designer side shows its published grid, a regular user the liked
/// grid (pages.md C9), saved stays viewer-private either way. The bell
/// affordance is C10's profile-tab entry (mobile-implementation.md §3);
/// the gear opens B7 settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  AppTabsActive _tab = AppTabsActive.first;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(profileViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: state.value?.profile.username ?? l10n.tabProfile,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(LucideIcons.bell, size: 22),
              tooltip: l10n.profileNotifications,
              onPressed: () => const NotificationsRoute().push<void>(context),
            ),
            IconButton(
              icon: const Icon(LucideIcons.settings, size: 22),
              tooltip: l10n.settingsTitle,
              onPressed: () => const SettingsRoute().push<void>(context),
            ),
          ],
        ),
      ),
      body: switch (state) {
        AsyncData(:final value?) => _ProfileBody(
          state: value,
          tab: _tab,
          onTab: (tab) => setState(() => _tab = tab),
        ),
        AsyncData() => Center(child: Text(l10n.profileSignedOut)),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const _ProfileSkeleton(),
      },
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
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
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
    required this.state,
    required this.tab,
    required this.onTab,
  });

  final OwnProfileState state;
  final AppTabsActive tab;
  final ValueChanged<AppTabsActive> onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final profile = state.profile;

    final metaLine = <String>[
      ?profile.location?.city,
      ?profile.bio,
      l10n.profileVaultPrivate,
    ].join(' · ');

    final gridPosts = tab == AppTabsActive.first
        ? state.gridPosts
        : state.savedPosts;

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                // MI-11: the freshness ring is the vault affordance —
                // tapping the ringed avatar opens C7 (pages.md C7).
                Semantics(
                  button: true,
                  label: l10n.profileVaultRing,
                  child: GestureDetector(
                    onTap: () => const VaultRoute().push<void>(context),
                    child: Avatar(
                      name: profile.displayName,
                      image: seedMediaImageOrNull(profile.avatarUrl),
                      size: AvatarSize.s96,
                      ring: Avatar.freshnessRing(state.vaultFreshness),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Expanded(
                        child: _StatColumn(
                          value: state.postsCount,
                          label: l10n.profilePosts,
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          value: state.followersCount,
                          label: l10n.profileFollowers,
                          onTap: () => FollowersRoute(
                            username: profile.username,
                          ).push<void>(context),
                        ),
                      ),
                      Expanded(
                        child: _StatColumn(
                          value: state.followingCount,
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
                Text(
                  profile.displayName,
                  style: typography.body16SemiBold.copyWith(
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metaLine,
                  style: typography.caption13.copyWith(color: colors.text2),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Button(
                    label: l10n.profileEditProfile,
                    kind: ButtonKind.quiet,
                    expand: true,
                    onPressed: () =>
                        const EditProfileRoute().push<void>(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Button(
                    label: l10n.profileMeasurementVault,
                    kind: ButtonKind.quiet,
                    expand: true,
                    onPressed: () => const VaultRoute().push<void>(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: AppTabs(
            first: AppTabItem.icon(
              LucideIcons.grid3X3,
              semanticLabel: state.designerEnabled
                  ? l10n.profileTabPosts
                  : l10n.profileTabLiked,
            ),
            second: AppTabItem.icon(
              LucideIcons.bookmark,
              semanticLabel: l10n.profileTabSaved,
            ),
            active: tab,
            onSelect: onTab,
          ),
        ),
        if (gridPosts.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: EmptyState(
                kind: EmptyStateKind.explore,
                line: tab == AppTabsActive.second
                    ? l10n.profileSavedEmpty
                    : state.designerEnabled
                    ? l10n.profilePostsEmpty
                    : l10n.profileLikedEmpty,
                onCta: () => const ExploreRoute().go(context),
              ),
            ),
          )
        else
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              childCount: gridPosts.length,
              (context, index) => _GridTile(post: gridPosts[index]),
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
