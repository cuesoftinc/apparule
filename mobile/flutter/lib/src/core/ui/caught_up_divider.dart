import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// CaughtUpDivider — the Figma `CaughtUpDivider` set (96:1214, single
/// component); web sibling `CaughtUpDivider.tsx`. MI-6: "You're all
/// caught up ✓" — accent check glyph between a hairline pair, shown after
/// 48h-old content (C2-caught-up, C10).
class CaughtUpDivider extends StatelessWidget {
  const CaughtUpDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: <Widget>[
          Expanded(child: Container(height: 1, color: colors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  LucideIcons.circleCheck,
                  size: 20,
                  color: colors.accentStart,
                ),
                const SizedBox(width: 8),
                Text(
                  "You're all caught up",
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Container(height: 1, color: colors.border)),
        ],
      ),
    );
  }
}
