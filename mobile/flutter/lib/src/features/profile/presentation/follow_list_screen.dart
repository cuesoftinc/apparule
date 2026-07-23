import 'dart:async' show unawaited;

import 'package:apparule/src/core/async/run_action.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/ui/tabs.dart';
import 'package:apparule/src/core/ui/user_row.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/feed/domain/user_summary.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_view_model.dart';
import 'package:apparule/src/features/profile/presentation/unfollow_confirm_sheet.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C12 — followers/following (canvas 205:7203; = B6 lists): count-titled
/// text tabs over UserRow lists with the MI-7 Follow morph (designers
/// only — regular users carry no trailing button), unfollow via the
/// confirm sheet, rows opening the C9 profile.
class FollowListScreen extends ConsumerStatefulWidget {
  const FollowListScreen({
    required this.username,
    required this.initialKind,
    super.key,
  });

  final String username;
  final FollowListKind initialKind;

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  late FollowListKind _kind = widget.initialKind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final followers = ref.watch(
      followListProvider(
        username: widget.username,
        kind: FollowListKind.followers,
      ),
    );
    final following = ref.watch(
      followListProvider(
        username: widget.username,
        kind: FollowListKind.following,
      ),
    );
    final active = _kind == FollowListKind.followers ? followers : following;

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: widget.username,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const ProfileRoute().go(context);
          }
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTabs(
            first: AppTabItem.text(
              l10n.followListFollowersTab(
                formatCount(followers.value?.length ?? 0),
              ),
            ),
            second: AppTabItem.text(
              l10n.followListFollowingTab(
                formatCount(following.value?.length ?? 0),
              ),
            ),
            active: _kind == FollowListKind.followers
                ? AppTabsActive.first
                : AppTabsActive.second,
            onSelect: (tab) => setState(
              () => _kind = tab == AppTabsActive.first
                  ? FollowListKind.followers
                  : FollowListKind.following,
            ),
          ),
          Expanded(
            // Value-preserving switch (CLASS 2): the follow fan-out
            // re-derives the whole family — the rendered rows must
            // survive it instead of dropping to the skeleton per tap
            // (D19).
            child: switch (active) {
              AsyncValue(:final value?) => _FollowList(
                rows: value,
                kind: _kind,
              ),
              AsyncError(:final error) => Center(child: Text('$error')),
              _ => ListView(
                padding: const EdgeInsets.all(16),
                children: const <Widget>[
                  Skeleton(),
                  SizedBox(height: 12),
                  Skeleton(),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  const _FollowList({required this.rows, required this.kind});

  final List<UserSummary> rows;
  final FollowListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    if (rows.isEmpty) {
      return Center(
        child: Text(
          kind == FollowListKind.followers
              ? l10n.followListNoFollowers
              : l10n.followListNoFollowing,
          style: typography.body14.copyWith(color: colors.text2),
        ),
      );
    }

    // The viewer's optimistic follow overlay — a tap morphs its row THIS
    // frame (`overlay[username] ?? serverValue`, D19), the reconciled
    // graph lands behind it.
    final overlay = ref.watch(followGraphControllerProvider);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final follows = overlay[row.username] ?? row.viewerFollows;
        // Canvas 205:7203 meta line: display name, designers suffixed.
        final meta = row.isDesigner
            ? l10n.followListDesignerMeta(row.displayName)
            : row.displayName;
        return UserRow(
          key: ValueKey<String>(row.username),
          username: row.username,
          meta: meta,
          image: seedMediaImageOrNull(row.avatarUrl),
          verified: row.verified,
          trailing: !row.isDesigner
              ? UserRowTrailing.none
              : follows
              ? UserRowTrailing.following
              : UserRowTrailing.follow,
          onTap: () =>
              PublicProfileRoute(username: row.username).push<void>(context),
          // Rollback + toast on failure ride runAction (CLASS 4) over
          // the controller's own overlay rollback.
          onFollow: () => unawaited(
            runAction(
              context,
              () => ref
                  .read(followGraphControllerProvider.notifier)
                  .setFollow(row.username, follow: true),
            ),
          ),
          onFollowingTap: () async {
            final confirmed = await showUnfollowConfirmSheet(
              context,
              username: row.username,
              image: seedMediaImageOrNull(row.avatarUrl),
            );
            if (confirmed && context.mounted) {
              await runAction(
                context,
                () => ref
                    .read(followGraphControllerProvider.notifier)
                    .setFollow(row.username, follow: false),
              );
            }
          },
        );
      },
    );
  }
}
