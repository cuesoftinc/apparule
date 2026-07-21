import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Temporary skeleton-wave scaffolding: the shared body every placeholder
/// screen renders until its C-series surface lands (§1 phase 3). Not a
/// design-system module — deleted screen by screen as replacements ship.
class SkeletonPlaceholder extends StatelessWidget {
  const SkeletonPlaceholder({
    required this.icon,
    required this.title,
    super.key,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final spacing = theme.extension<AppSpacing>()!;
    final typography = theme.extension<AppTypography>()!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: colors.text2),
            SizedBox(height: spacing.s4),
            Text(
              title,
              style: typography.title20SemiBold.copyWith(color: colors.text),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.s2),
            Text(
              context.l10n.placeholderBody,
              style: typography.body14.copyWith(color: colors.text2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
