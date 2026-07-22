import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The Figma `Button` set's `kind` axis (39:66) — `quiet-danger` is the
/// 2026-07-22 danger-ladder addition (row-level destructive; filled
/// [destructive] appears only on armed/confirm surfaces).
enum ButtonKind {
  /// `gradient-primary` — accent-start → accent-end fill, on-accent label.
  gradientPrimary,

  /// `quiet` — hairline border, elevated surface, text-token label.
  quiet,

  /// `destructive` — error fill, on-accent label (armed/confirm surfaces).
  destructive,

  /// `link` — bare link-token label, no chrome.
  link,

  /// `quiet-danger` — quiet chrome, error-token label (Figma 501:2; the
  /// row-level rung of the danger ladder).
  quietDanger,
}

/// The Figma `size` axis: `md` (44px, 16px padding, 14px label) /
/// `sm` (36px, 12px padding, 13px label).
enum ButtonSize {
  /// 44px tall.
  md,

  /// 36px tall.
  sm,
}

/// Button — one module per Figma component set (mobile-implementation.md
/// §7); web sibling `Button.tsx`. Axes: `kind` × `size` × `state`
/// (default/pressed/disabled/loading). The `state` axis maps to runtime
/// state, mirroring the web sibling: pressed is a real interaction
/// (overlay tint + 0.98 scale, fast/standard motion tokens), disabled is
/// `onPressed == null` (40% opacity), loading swaps the label for a
/// spinner at fixed width and blocks re-taps.
class Button extends StatefulWidget {
  const Button({
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.gradientPrimary,
    this.size = ButtonSize.md,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  /// The label text (copy comes from the consumer).
  final String label;

  /// Tap handler; `null` renders the `disabled` state.
  final VoidCallback? onPressed;

  final ButtonKind kind;
  final ButtonSize size;

  /// The `loading` state cell — spinner replaces the label; taps blocked.
  final bool loading;

  /// Stretch to the parent's width (the web sibling's `w-full` usage —
  /// PostCard CTA, PaymentBox pay row).
  final bool expand;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final motion = theme.extension<AppMotion>()!;
    final typography = theme.extension<AppTypography>()!;

    final md = widget.size == ButtonSize.md;
    final height = md ? 44.0 : 36.0;
    final horizontal = md ? 16.0 : 12.0;
    final labelStyle = (md ? typography.body14 : typography.caption13).copyWith(
      fontWeight: FontWeight.w600,
    );

    // Kind → chrome. Fills/borders bind base hues; the quiet-danger label
    // binds the error token over quiet chrome (Figma 501:2).
    Gradient? gradient;
    Color? background;
    var side = BorderSide.none;
    Color foreground;
    switch (widget.kind) {
      case ButtonKind.gradientPrimary:
        gradient = colors.accentGradient;
        foreground = colors.onAccent;
      case ButtonKind.quiet:
        background = colors.bgElev;
        side = BorderSide(color: colors.border);
        foreground = colors.text;
      case ButtonKind.destructive:
        background = colors.error;
        foreground = colors.onAccent;
      case ButtonKind.link:
        foreground = colors.link;
      case ButtonKind.quietDanger:
        background = colors.bgElev;
        side = BorderSide(color: colors.border);
        foreground = colors.error;
    }

    // Pressed = Figma overlay tint (16% black inset on fills, 18% gray on
    // quiet/link) + active scale — the web sibling's `active:` recipe.
    final filled =
        widget.kind == ButtonKind.gradientPrimary ||
        widget.kind == ButtonKind.destructive;
    final pressedOverlay = filled
        ? const Color(0xFF000000).withValues(alpha: 0.16)
        : const Color(0xFF808080).withValues(alpha: 0.18);

    final spinnerSize = md ? 18.0 : 16.0;
    final spinnerColor = filled ? colors.onAccent : colors.text2;

    var child = widget.loading
        ? SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: spinnerColor,
            ),
          )
        : Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: labelStyle.copyWith(color: foreground),
          );

    child = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      decoration: BoxDecoration(
        gradient: gradient,
        color: background,
        border: side == BorderSide.none ? null : Border.fromBorderSide(side),
        borderRadius: BorderRadius.circular(radii.card),
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[child],
      ),
    );

    if (_pressed && _enabled) {
      child = Stack(
        children: <Widget>[
          child,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: pressedOverlay,
                borderRadius: BorderRadius.circular(radii.card),
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.loading ? widget.label : null,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          onTap: _enabled ? widget.onPressed : null,
          child: Opacity(
            // Figma: disabled cells render the default chrome at 40%.
            opacity: widget.onPressed == null && !widget.loading ? 0.4 : 1,
            child: AnimatedScale(
              scale: _pressed && _enabled ? 0.98 : 1,
              duration: motion.fast,
              curve: motion.standardEasing,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
