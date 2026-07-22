import 'dart:async' show unawaited;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';

/// SpringBadge — the MI-16 count badge (design.md §4: "Orders tab badge
/// increments with springy scale"): the like-red count pill that pops
/// 1→1.3→1 with a spring settle whenever [count] INCREASES (decrements
/// and first paint stay still — the pop announces news, not layout).
///
/// MI-16 is one of the MIs that names a spring (§2: "springs only where
/// an MI names one"), hence the elastic settle rather than a token curve.
/// Reduced motion renders statically (design.md §5).
class SpringBadge extends StatefulWidget {
  const SpringBadge({required this.count, super.key});

  /// The badge count; renders nothing for `<= 0`.
  final int count;

  /// The pop length — spring settle inclusive.
  static const Duration duration = Duration(milliseconds: 400);

  @override
  State<SpringBadge> createState() => _SpringBadgeState();
}

class _SpringBadgeState extends State<SpringBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: SpringBadge.duration,
  );

  // 1 → 1.3 fast, then a springy settle back to 1; at rest (controller
  // value 0 or 1) the scale is exactly 1, so goldens hold byte-stable.
  late final Animation<double> _scale = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ],
  ).animate(_pop);

  @override
  void didUpdateWidget(SpringBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final increment = widget.count > oldWidget.count && widget.count > 0;
    if (increment && !MediaQuery.disableAnimationsOf(context)) {
      unawaited(_pop.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        constraints: const BoxConstraints(minWidth: 16),
        height: 16,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.like,
          borderRadius: BorderRadius.circular(radii.pill),
        ),
        child: Text(
          formatCount(widget.count),
          style: typography.micro12.copyWith(
            fontSize: 10,
            height: 1.6,
            fontWeight: FontWeight.w600,
            color: colors.onAccent,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
