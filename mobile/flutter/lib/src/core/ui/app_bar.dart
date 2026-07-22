import 'dart:math' as math;

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
///
/// Notch-aware like Material's `AppBar`: the surface (background or
/// over-media scrim) extends up behind the status bar while the 56px
/// content row insets below it — [preferredSize] stays the content
/// height because `Scaffold` adds the top padding to the slot itself.
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

    final leadingWidget = kind != AppTopBarKind.root && onBack != null
        ? Semantics(
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
          )
        : null;
    final trailingWidget = trailing != null
        ? IconTheme.merge(
            data: IconThemeData(color: contentColor),
            child: trailing!,
          )
        : null;

    final Widget content;
    if (kind == AppTopBarKind.root) {
      // Figma master: the root brand bar keeps the left-aligned gradient
      // wordmark in flow — exempt from the centering ruling.
      content = Row(
        children: <Widget>[
          Expanded(
            child: Align(
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
            ),
          ),
          if (trailingWidget != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: trailingWidget,
            ),
        ],
      );
    } else {
      // Centered-title ruling (user, 2026-07-22): the title is a
      // full-width layer centered on the BAR, with the leading/trailing
      // slots overlaid at the edges — never centered in leftover flow
      // space (that grew into hidden-slot space and skewed right). Long
      // titles pad by the MAX slot width so the ellipsis stays
      // symmetric and clear of both slots.
      content = CustomMultiChildLayout(
        delegate: _CenteredBarLayout(
          hasLeading: leadingWidget != null,
          hasTrailing: trailingWidget != null,
        ),
        children: <Widget>[
          if (leadingWidget != null)
            LayoutId(id: _BarSlot.leading, child: leadingWidget),
          LayoutId(
            id: _BarSlot.title,
            child: Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: typography.body16SemiBold.copyWith(color: contentColor),
            ),
          ),
          if (trailingWidget != null)
            LayoutId(id: _BarSlot.trailing, child: trailingWidget),
        ],
      );
    }

    return DecoratedBox(
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
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            // The mode bar's row sits above its 1px bottom border — the
            // decoration padding the pre-inset Container applied.
            bottom: overMedia ? 0 : 1,
          ),
          child: content,
        ),
      ),
    );
  }
}

enum _BarSlot { leading, title, trailing }

/// The sub/over-media bar layout: slots hug the edges, the title layer
/// spans the full bar and centers on it, inset on BOTH sides by the max
/// slot width (centered-title ruling, 2026-07-22).
class _CenteredBarLayout extends MultiChildLayoutDelegate {
  _CenteredBarLayout({required this.hasLeading, required this.hasTrailing});

  final bool hasLeading;
  final bool hasTrailing;

  @override
  void performLayout(Size size) {
    var leadingWidth = 0.0;
    var trailingWidth = 0.0;
    if (hasLeading) {
      final slot = layoutChild(_BarSlot.leading, BoxConstraints.loose(size));
      positionChild(
        _BarSlot.leading,
        Offset(0, (size.height - slot.height) / 2),
      );
      leadingWidth = slot.width;
    }
    if (hasTrailing) {
      final slot = layoutChild(_BarSlot.trailing, BoxConstraints.loose(size));
      positionChild(
        _BarSlot.trailing,
        Offset(size.width - slot.width, (size.height - slot.height) / 2),
      );
      trailingWidth = slot.width;
    }
    final inset = math.max(leadingWidth, trailingWidth);
    final title = layoutChild(
      _BarSlot.title,
      BoxConstraints(
        maxWidth: math.max(0, size.width - 2 * inset),
        maxHeight: size.height,
      ),
    );
    positionChild(
      _BarSlot.title,
      Offset((size.width - title.width) / 2, (size.height - title.height) / 2),
    );
  }

  @override
  bool shouldRelayout(covariant _CenteredBarLayout oldDelegate) =>
      oldDelegate.hasLeading != hasLeading ||
      oldDelegate.hasTrailing != hasTrailing;
}
