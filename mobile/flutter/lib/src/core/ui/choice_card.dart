import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// ChoiceCard — the create chooser's choice-card language (Figma
/// `choice-card/*`, 548:2750/2759; C1b card idiom): 28px glyph · Body/16
/// Semi Bold title + Caption/13 `text-2` subtitle · trailing chevron, on
/// the elevated surface at radius 12. [primary] carries the 1.5px
/// `accent-start` border ("Take measurements" is the chooser's primary
/// option); secondary cards keep the 1px `border` stroke.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.primary = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// The accent-bordered primary option (Figma
  /// `choice-card/take-measurements`).
  final bool primary;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      // One named button node — the visible title/subtitle are
      // presentational; the label carries both (named-control canon).
      container: true,
      excludeSemantics: true,
      button: true,
      label: '$title. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
          decoration: BoxDecoration(
            color: colors.bgElev,
            border: primary
                ? Border.all(color: colors.accentStart, width: 1.5)
                : Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 28, color: colors.text),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: typography.body16SemiBold.copyWith(
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: typography.caption13.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Icon(LucideIcons.chevronRight, size: 20, color: colors.text),
            ],
          ),
        ),
      ),
    );
  }
}
