import 'dart:async';

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_haptics.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Lucide heart/bookmark path data (24×24 grid) — inlined as SVG because
// the liked/saved states FILL the glyph (web `fill-like`/`fill-text`),
// which an icon font cannot express.
const String _heartPath =
    'M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 '
    '2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z';
const String _bookmarkPath =
    'm19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z';

String _lucideSvg(String path, {required Color stroke, Color? fill}) {
  String hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="${fill == null ? 'none' : hex(fill)}" stroke="${hex(stroke)}" '
      'stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      ' <path d="$path"/></svg>';
}

/// The DS Lucide heart with a fillable body — the liked state FILLS the
/// glyph (web `fill-like` parity), which the icon font cannot express.
/// ActionRow's like control and C11's comment hearts share it (D60).
class LucideHeart extends StatelessWidget {
  const LucideHeart({
    required this.color,
    this.filled = false,
    this.size = 24,
    super.key,
  });

  final Color color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _lucideSvg(_heartPath, stroke: color, fill: filled ? color : null),
      width: size,
      height: size,
    );
  }
}

/// ActionRow — the Figma `ActionRow` set (46:140); web sibling
/// `ActionRow.tsx`. Axes: `liked` f/t · `saved` f/t — the PostCard action
/// row (♥ 💬 ↗ ⌁save). MI-2: the like tap scales 1→0.8→1.15→1 (240ms
/// spring) and fills like-red; unlike has no animation (IG asymmetry).
/// MI-3: save dips −4px then fills. Icon-only controls carry semantics
/// labels (named-control canon); state changes announce via a live region.
class ActionRow extends StatefulWidget {
  const ActionRow({
    required this.liked,
    required this.saved,
    required this.likeCount,
    required this.onToggleLike,
    required this.onToggleSave,
    this.onComment,
    this.onShare,
    super.key,
  });

  final bool liked;
  final bool saved;

  /// Drives the polite live-region announcement (design.md §5).
  final int likeCount;

  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  State<ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<ActionRow> with TickerProviderStateMixin {
  late final AnimationController _likeBurst;
  late final Animation<double> _likeScale;
  late final AnimationController _saveDip;
  late final Animation<double> _saveOffset;

  @override
  void initState() {
    super.initState();
    _likeBurst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _likeScale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1), weight: 1),
    ]).animate(_likeBurst);
    _saveDip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _saveOffset = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(_saveDip);
  }

  @override
  void dispose() {
    _likeBurst.dispose();
    _saveDip.dispose();
    super.dispose();
  }

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Row(
      children: <Widget>[
        _ActionButton(
          semanticLabel: widget.liked ? 'Unlike' : 'Like',
          toggled: widget.liked,
          onTap: () {
            if (!widget.liked) {
              // MI-2: animate on like only (IG asymmetry); MI-20 pairs
              // the light haptic with it (mobile Instagram-feel — the
              // live-QA "get to the level of the web" pass).
              if (!_reducedMotion) unawaited(_likeBurst.forward(from: 0));
              AppHaptics.light();
            }
            widget.onToggleLike();
          },
          child: ScaleTransition(
            scale: _likeScale,
            child: LucideHeart(
              color: widget.liked ? colors.like : colors.text,
              filled: widget.liked,
            ),
          ),
        ),
        _ActionButton(
          semanticLabel: 'Comments',
          onTap: widget.onComment,
          child: Icon(LucideIcons.messageCircle, size: 24, color: colors.text),
        ),
        _ActionButton(
          semanticLabel: 'Share',
          onTap: widget.onShare,
          child: Icon(LucideIcons.send, size: 24, color: colors.text),
        ),
        // Live region mirrors the web sibling's aria-live like announcement.
        Semantics(
          liveRegion: true,
          label: widget.liked
              ? 'Liked. ${formatCount(widget.likeCount)} likes'
              : '${formatCount(widget.likeCount)} likes',
          child: const SizedBox.shrink(),
        ),
        const Spacer(),
        _ActionButton(
          semanticLabel: widget.saved ? 'Remove from saved' : 'Save',
          toggled: widget.saved,
          onTap: () {
            if (!_reducedMotion) unawaited(_saveDip.forward(from: 0));
            // MI-20: light haptic on save (set only — the un-action
            // stays quiet, the MI-2 asymmetry).
            if (!widget.saved) AppHaptics.light();
            widget.onToggleSave();
          },
          child: AnimatedBuilder(
            animation: _saveOffset,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _saveOffset.value),
              child: child,
            ),
            child: SvgPicture.string(
              _lucideSvg(
                _bookmarkPath,
                stroke: colors.text,
                fill: widget.saved ? colors.text : null,
              ),
              width: 24,
              height: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.semanticLabel,
    required this.child,
    required this.onTap,
    this.toggled,
  });

  final String semanticLabel;
  final Widget child;
  final VoidCallback? onTap;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      toggled: toggled,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        // 44px minimum hit target (design.md §5).
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}
