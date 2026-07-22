import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// MorphSwap — the MI-7 150ms control morph (design.md §4: "Follow
/// gradient-filled → on tap morphs 150ms to quiet Following") as a shared
/// primitive: consumers key the [child] by its state and the swap
/// cross-morphs (fade + subtle scale) instead of jumping frames.
///
/// 150ms is the §4 exact value (MI specs quote exact values; the token
/// durations are the defaults). Easing rides the token curves. Reduced
/// motion degrades to the plain ≤150ms opacity crossfade (design.md §5).
class MorphSwap extends StatelessWidget {
  const MorphSwap({required this.child, super.key});

  /// The §4 morph duration — exact MI value, deliberately not a token.
  static const Duration duration = Duration(milliseconds: 150);

  /// The current state's widget, keyed by state (`ValueKey(following)`)
  /// so the switcher sees a swap.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = Theme.of(context).extension<AppMotion>()!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: motion.standardEasing,
      switchOutCurve: motion.exitEasing,
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        if (reducedMotion) return fade;
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
          child: fade,
        );
      },
      child: child,
    );
  }
}
