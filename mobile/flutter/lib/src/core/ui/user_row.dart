import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/morph_swap.dart';
import 'package:flutter/material.dart';

/// The Figma `UserRow` set's `trailing` axis — Follow (gradient) /
/// Following (quiet) / none (MI-7 morph; non-designers carry no button).
enum UserRowTrailing {
  /// Gradient "Follow" — the viewer doesn't follow this designer yet.
  follow,

  /// Quiet "Following" — tapping opens the MI-7 unfollow confirm.
  following,

  /// No trailing control (regular users can't be followed).
  none,
}

/// UserRow — the Figma `UserRow` set (§8.2b social rows); web sibling
/// `UserRow.tsx`. Avatar 32/44 + username + meta line + the MI-7
/// trailing morph. The row body is tappable ([onTap] opens the profile);
/// the trailing button routes to [onFollow] / [onFollowingTap] so
/// consumers arm the unfollow confirm instead of toggling blind.
/// Consumed by C12 followers/following and B2-parity search sections.
class UserRow extends StatelessWidget {
  const UserRow({
    required this.username,
    this.meta,
    this.image,
    this.verified = false,
    this.avatarSize = AvatarSize.s44,
    this.trailing = UserRowTrailing.none,
    this.onTap,
    this.onFollow,
    this.onFollowingTap,
    super.key,
  });

  final String username;

  /// Second line — display name, "· designer" suffix, bio segment.
  final String? meta;

  final ImageProvider<Object>? image;
  final bool verified;

  /// The Figma `avatar` axis: 32 (dense sheets) / 44 (default lists).
  final AvatarSize avatarSize;

  final UserRowTrailing trailing;

  /// Row-body tap — opens the profile.
  final VoidCallback? onTap;

  /// Gradient "Follow" tap (MI-7 morph, optimistic at the consumer).
  final VoidCallback? onFollow;

  /// Quiet "Following" tap — consumers open the unfollow confirm sheet
  /// (MI-7: unfollow is never a blind toggle).
  final VoidCallback? onFollowingTap;

  VoidCallback? get _trailingHandler => switch (trailing) {
    UserRowTrailing.follow => onFollow,
    UserRowTrailing.following => onFollowingTap,
    UserRowTrailing.none => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    final row = Row(
      children: <Widget>[
        Avatar(
          name: username,
          image: image,
          size: avatarSize,
          badge: verified ? AvatarBadge.designerVerified : AvatarBadge.none,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.body14.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
              if (meta case final meta?)
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.caption13.copyWith(color: colors.text2),
                ),
            ],
          ),
        ),
        // Prop-contract (CLASS 3): the trailing morph renders only when
        // its handler exists — a Follow button that cannot follow is a
        // dead affordance.
        if (trailing != UserRowTrailing.none &&
            _trailingHandler != null) ...<Widget>[
          const SizedBox(width: 12),
          // MI-7: the state swap cross-morphs 150ms (D55), labels off
          // the l10n catalog like every consumer surface (D69).
          MorphSwap(
            child: Button(
              key: ValueKey<UserRowTrailing>(trailing),
              label: trailing == UserRowTrailing.follow
                  ? context.l10n.exploreFollow
                  : context.l10n.exploreFollowing,
              kind: trailing == UserRowTrailing.follow
                  ? ButtonKind.gradientPrimary
                  : ButtonKind.quiet,
              size: ButtonSize.sm,
              onPressed: _trailingHandler,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: row,
      );
    }
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: row,
        ),
      ),
    );
  }
}
