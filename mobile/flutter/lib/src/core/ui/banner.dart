import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `Banner` set's `tone` axis (95:1220).
enum BannerTone { info, warn, error, success }

/// AppBanner — the Figma `Banner` set (95:1220; file name canonical, class
/// renamed off the framework's debug `Banner`); web sibling `Banner.tsx`.
/// Axes: `tone` info/warn/error/success · `dismiss`
/// persistent/dismissable, plus the action-link slot (Retry, support,
/// explainer). Consumed by C5-step1 (freshness) and C13-orders (KYC
/// lapse). Warn/success action text binds the AA `-text` variants; the
/// leading icon keeps the base hue (fills/borders/icons canon).
class AppBanner extends StatefulWidget {
  const AppBanner({
    required this.message,
    this.tone = BannerTone.info,
    this.dismissable = false,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Banner body copy.
  final String message;

  final BannerTone tone;

  /// The `dismiss` axis — `true` renders the trailing ✕; the banner
  /// removes itself and notifies [onDismiss].
  final bool dismissable;

  final VoidCallback? onDismiss;

  /// Action-link slot label (`null` = no action).
  final String? actionLabel;

  final VoidCallback? onAction;

  @override
  State<AppBanner> createState() => _AppBannerState();
}

class _AppBannerState extends State<AppBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    // Figma master: info=circled-i, warn/error=triangle, success=check.
    final icon = switch (widget.tone) {
      BannerTone.info => LucideIcons.info,
      BannerTone.warn || BannerTone.error => LucideIcons.triangleAlert,
      BannerTone.success => LucideIcons.circleCheck,
    };
    final hue = switch (widget.tone) {
      BannerTone.info => colors.link,
      BannerTone.warn => colors.warn,
      BannerTone.error => colors.error,
      BannerTone.success => colors.success,
    };
    // Action links bind the tone token, readable on the /10 tint — warn/
    // success bind their AA `-text` variants (design.md §2); link/error
    // base values already clear 4.5:1 there.
    final actionColor = switch (widget.tone) {
      BannerTone.info => colors.link,
      BannerTone.warn => colors.warnText,
      BannerTone.error => colors.error,
      BannerTone.success => colors.successText,
    };

    return Semantics(
      liveRegion: widget.tone == BannerTone.error,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hue.withValues(alpha: 0.10),
          border: Border.all(color: hue.withValues(alpha: 0.40)),
          borderRadius: BorderRadius.circular(radii.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Icon(icon, size: 20, color: hue),
            ),
            Expanded(
              child: Text(
                widget.message,
                style: typography.body14.copyWith(color: colors.text),
              ),
            ),
            if (widget.actionLabel != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: widget.onAction,
                  child: Text(
                    widget.actionLabel!,
                    style: typography.body14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
                  ),
                ),
              ),
            if (widget.dismissable)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Semantics(
                  // Own node — assistive tech activates it separately
                  // from the banner copy (named-control canon).
                  container: true,
                  label: 'Dismiss',
                  button: true,
                  child: InkResponse(
                    onTap: () {
                      setState(() => _dismissed = true);
                      widget.onDismiss?.call();
                    },
                    radius: 16,
                    child: Icon(LucideIcons.x, size: 16, color: colors.text2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
