import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:flutter/material.dart';

/// MI-7: unfollow always goes through a confirm sheet (prevents
/// accidental) — web sibling `UnfollowConfirmSheet`. Resolves true when
/// the user confirms.
Future<bool> showUnfollowConfirmSheet(
  BuildContext context, {
  required String username,
  ImageProvider<Object>? image,
}) async {
  final confirmed = await Sheet.show<bool>(
    context,
    title: context.l10n.unfollowTitle,
    child: _UnfollowConfirm(username: username, image: image),
  );
  return confirmed ?? false;
}

class _UnfollowConfirm extends StatelessWidget {
  const _UnfollowConfirm({required this.username, this.image});

  final String username;
  final ImageProvider<Object>? image;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Avatar(name: username, image: image, size: AvatarSize.s56),
        const SizedBox(height: 12),
        Text(
          l10n.unfollowBody,
          textAlign: TextAlign.center,
          style: typography.body14.copyWith(color: colors.text2),
        ),
        const SizedBox(height: 16),
        Button(
          label: l10n.unfollowConfirm(username),
          kind: ButtonKind.destructive,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 8),
        Button(
          label: l10n.unfollowCancel,
          kind: ButtonKind.quiet,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
