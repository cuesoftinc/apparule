import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// GoogleAuthButton — the single auth CTA (X-1), the mobile counterpart
/// of web's `GoogleAuthButton` (design.md §8.2b contract): Google 'G'
/// mark + label · default / pressed / loading / disabled · token-true
/// through the theme extensions. 48px tall, card radius, hairline
/// border, elevated surface; loading keeps the G and swaps the label
/// for a spinner. Exact Figma-master fidelity (83:887) lands with the
/// design wave's golden pass.
class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final spacing = theme.extension<AppSpacing>()!;
    final typography = theme.extension<AppTypography>()!;
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: EdgeInsets.symmetric(horizontal: spacing.s6),
        backgroundColor: colors.bgElev,
        foregroundColor: colors.text,
        disabledForegroundColor: colors.text.withValues(alpha: 0.4),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.card),
        ),
        textStyle: typography.body16SemiBold,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/google_g.svg',
            width: 18,
            height: 18,
          ),
          SizedBox(width: spacing.s3),
          if (loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.text2,
              ),
            )
          else
            Text(label),
        ],
      ),
    );
  }
}
