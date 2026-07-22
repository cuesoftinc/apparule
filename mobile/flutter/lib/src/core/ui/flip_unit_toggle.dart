import 'dart:math' as math;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// FlipUnitToggle — the MI-13 unit flip (design.md §4: "unit toggle cm/in
/// flips with 3D x-rotation 200ms") as a shared primitive: consumers key
/// the [child] by the unit (`ValueKey(unit)`) and the swap rotates about
/// the x-axis with perspective.
///
/// 200ms is the `base` motion token; easing rides the token curves.
/// Reduced motion degrades to a plain opacity crossfade (design.md §5).
class FlipUnitToggle extends StatelessWidget {
  const FlipUnitToggle({required this.child, super.key});

  /// The current unit's widget, keyed by unit so the switcher sees a
  /// swap.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = Theme.of(context).extension<AppMotion>()!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: motion.base,
      switchInCurve: motion.standardEasing,
      switchOutCurve: motion.exitEasing,
      transitionBuilder: (child, animation) {
        if (reducedMotion) {
          return FadeTransition(opacity: animation, child: child);
        }
        return _FlipTransition(animation: animation, child: child);
      },
      child: child,
    );
  }
}

/// Rotates its child about the x-axis: the incoming child (animation
/// 0→1) stands up from 90°; the outgoing child (1→0) falls back to 90° —
/// together they read as one 3D flip.
class _FlipTransition extends AnimatedWidget {
  const _FlipTransition({required Animation<double> animation, this.child})
    : super(listenable: animation);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final angle = (1 - animation.value) * (math.pi / 2);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        // Perspective — without it the rotation reads as a vertical
        // squash, not a flip.
        ..setEntry(3, 2, 0.002)
        ..rotateX(angle),
      child: child,
    );
  }
}
