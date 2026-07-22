import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// StepSlide — the MI-10 step transition (design.md §4: "step transitions
/// slide 24px") as a shared primitive: consumers key the [child] by step
/// index and the swap slides the incoming body 24px in (from the right
/// going forward, from the left with [reverse]) while it fades.
///
/// Duration is the `base` motion token (§2: MIs quote exact values, the
/// tokens are the defaults — MI-10 names only the 24px distance); easing
/// rides the token curves. Reduced motion degrades to the plain opacity
/// crossfade (design.md §5).
class StepSlide extends StatelessWidget {
  const StepSlide({required this.child, this.reverse = false, super.key});

  /// The §4 slide distance — exact MI value.
  static const double distance = 24;

  /// The current step's body, keyed by step so the switcher sees a swap.
  final Widget child;

  /// True when stepping backwards — the body slides in from the left.
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final motion = Theme.of(context).extension<AppMotion>()!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final direction = reverse ? -1.0 : 1.0;

    return AnimatedSwitcher(
      duration: motion.base,
      switchInCurve: motion.standardEasing,
      switchOutCurve: motion.exitEasing,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        if (reducedMotion) return fade;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.translate(
            offset: Offset((1 - animation.value) * distance * direction, 0),
            child: child,
          ),
          child: fade,
        );
      },
      child: child,
    );
  }
}
