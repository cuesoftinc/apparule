import 'dart:async';

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The Figma `StatusPill` set's `status` axis (47:135) — the 10 order
/// states plus the vault freshness ladder ([Decided 2026-07-16] mapping).
enum StatusPillValue {
  requested('Requested'),
  quoted('Quoted'),
  paid('Paid'),
  inProgress('In progress'),
  shipped('Shipped'),
  delivered('Delivered'),
  refunded('Refunded'),
  declined('Declined'),
  disputed('Disputed'),
  cancelled('Cancelled'),
  fresh('Fresh'),
  aging('Aging'),
  stale('Stale');

  const StatusPillValue(this.label);

  /// Figma masters label pills in sentence case ("In progress").
  final String label;
}

/// StatusPill — the Figma `StatusPill` set (47:135); web sibling
/// `StatusPill.tsx`. Borderless pills: a 14% tint of the status token
/// behind a 12px semibold label; the label binds the AA `-text` variants
/// where the base hue misses 4.5:1 on its own tint (design.md §2 contrast
/// canon). `fresh` tints and clips the accent gradient. MI-14: status
/// changes pulse once (scale 1→1.06→1) with a color crossfade.
class StatusPill extends StatefulWidget {
  const StatusPill({required this.status, super.key});

  final StatusPillValue status;

  @override
  State<StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 1),
    ]).animate(_pulse);
  }

  @override
  void didUpdateWidget(StatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    // MI-14: pulse once when the status value changes.
    if (oldWidget.status != widget.status &&
        !MediaQuery.disableAnimationsOf(context)) {
      unawaited(_pulse.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final motion = theme.extension<AppMotion>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    // [Decided 2026-07-16] order-state → token mapping: quoted/shipped →
    // link · paid/delivered → success · in_progress/refunded → warn ·
    // declined/disputed → error · requested/cancelled → text-2; freshness
    // rides the same ladder (aging → warn, stale → text-2).
    final (Color tint, Color label) = switch (widget.status) {
      StatusPillValue.quoted ||
      StatusPillValue.shipped => (colors.link, colors.link),
      StatusPillValue.paid ||
      StatusPillValue.delivered => (colors.success, colors.successText),
      StatusPillValue.inProgress ||
      StatusPillValue.refunded ||
      StatusPillValue.aging => (colors.warn, colors.warnText),
      StatusPillValue.declined ||
      StatusPillValue.disputed => (colors.error, colors.error),
      StatusPillValue.requested ||
      StatusPillValue.cancelled ||
      StatusPillValue.stale => (colors.text2, colors.text2Text),
      StatusPillValue.fresh => (colors.accentStart, colors.accentText),
    };

    final fresh = widget.status == StatusPillValue.fresh;
    final labelStyle = typography.micro12.copyWith(
      fontWeight: FontWeight.w600,
      color: label,
    );

    Widget text = Text(widget.status.label, style: labelStyle);
    if (fresh) {
      // Figma master: the fresh label clips the accent gradient.
      text = ShaderMask(
        shaderCallback: (bounds) => colors.accentGradient.createShader(bounds),
        child: Text(
          widget.status.label,
          style: labelStyle.copyWith(color: colors.onAccent),
        ),
      );
    }

    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: motion.base,
        curve: motion.standardEasing,
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radii.pill),
          // 14% tint of the status token; fresh tints both gradient stops
          // (Figma cannot bind a gradient stop to a variable — two stops,
          // design.md §7).
          color: fresh ? null : tint.withValues(alpha: 0.14),
          gradient: fresh
              ? LinearGradient(
                  colors: <Color>[
                    colors.accentStart.withValues(alpha: 0.14),
                    colors.accentEnd.withValues(alpha: 0.14),
                  ],
                )
              : null,
        ),
        child: text,
      ),
    );
  }
}
