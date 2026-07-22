import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `AppBar` set's `kind` axis (85:994).
enum AppTopBarKind {
  /// Root screens — gradient wordmark title + trailing action slot.
  root,

  /// Sub screens — chevron-left back, centred 16px title, trailing slot.
  sub,

  /// Over-media chrome — transparent over a black→transparent scrim; raw
  /// white content is the documented on-media token exception.
  overMedia,
}

/// AppTopBar — the Figma `AppBar` set (85:994; file name canonical, class
/// renamed off Material's `AppBar`). Consumed by every C-frame except the
/// full-bleed C6 camera/processing frames and C1/C1b.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    this.kind = AppTopBarKind.root,
    this.title,
    this.onBack,
    this.trailing,
    super.key,
  });

  final AppTopBarKind kind;

  /// Root: the wordmark text. Sub/over-media: the centred screen title.
  final String? title;

  /// Sub/over-media: the chevron-left back action.
  final VoidCallback? onBack;

  /// Trailing action slot.
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final overMedia = kind == AppTopBarKind.overMedia;
    // On-media capture/photo chrome — raw white on a scrim is the
    // documented token exception (c-series inventory; design.md §2).
    const onMediaWhite = Color(0xFFFFFFFF);
    final contentColor = overMedia ? onMediaWhite : colors.text;

    Widget titleWidget;
    if (kind == AppTopBarKind.root) {
      // Figma master: the root bar paints the gradient wordmark.
      titleWidget = Align(
        alignment: Alignment.centerLeft,
        child: ShaderMask(
          shaderCallback: (bounds) =>
              colors.accentGradient.createShader(bounds),
          child: Text(
            title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.title20SemiBold.copyWith(
              // The shader needs an opaque base to mask.
              color: colors.onAccent,
            ),
          ),
        ),
      );
    } else {
      titleWidget = Text(
        title ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: typography.body16SemiBold.copyWith(color: contentColor),
      );
    }

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: overMedia
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x66000000), Color(0x00000000)],
              ),
            )
          : BoxDecoration(
              color: colors.bg,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
      child: Row(
        children: <Widget>[
          if (kind != AppTopBarKind.root && onBack != null)
            Semantics(
              label: 'Back',
              button: true,
              child: InkResponse(
                onTap: onBack,
                radius: 22,
                borderRadius: BorderRadius.circular(radii.pill),
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  transform: Matrix4.translationValues(-8, 0, 0),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.chevronLeft,
                    size: 24,
                    color: contentColor,
                  ),
                ),
              ),
            ),
          Expanded(child: titleWidget),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconTheme.merge(
                data: IconThemeData(color: contentColor),
                child: trailing!,
              ),
            ),
        ],
      ),
    );
  }
}
