import 'dart:async' show unawaited;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// TypingBubble — the MI-17 responding pulse (design.md §4: "request
/// thread shows designer 'responding…' three-dot pulse"): an incoming
/// thread bubble carrying three dots that pulse in a staggered wave.
///
/// The bubble chrome mirrors the C8 thread's incoming bubbles (bg-elev,
/// hairline border, card radius). Reduced motion renders the dots
/// statically (design.md §5 — a repeating pulse has no ≤150ms fallback).
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  /// One full three-dot wave.
  static const Duration cycle = Duration(milliseconds: 1200);

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: TypingBubble.cycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wave
        ..stop()
        ..value = 0;
    } else if (!_wave.isAnimating) {
      unawaited(_wave.repeat());
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;

    return Semantics(
      label: 'Responding',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgElev,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(radii.card),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var dot = 0; dot < 3; dot++) ...<Widget>[
              if (dot > 0) const SizedBox(width: 4),
              _PulsingDot(wave: _wave, index: dot, color: colors.text2),
            ],
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot({
    required this.wave,
    required this.index,
    required this.color,
  });

  final AnimationController wave;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Each dot brightens over a 40% window of the cycle, staggered 20%
    // apart — the classic wave.
    final animation = CurvedAnimation(
      parent: wave,
      curve: Interval(
        index * 0.2,
        index * 0.2 + 0.4,
        curve: Curves.easeInOut,
      ),
    );
    return FadeTransition(
      opacity: TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 1), weight: 1),
        TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.3), weight: 1),
      ]).animate(animation),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox(width: 6, height: 6),
      ),
    );
  }
}
