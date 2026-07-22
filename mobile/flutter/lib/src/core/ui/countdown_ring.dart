import 'dart:math' as math;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The Figma `CountdownRing` set's `count` axis (60:590) — the 3/2/1
/// capture ticks (Dart identifiers cannot start with a digit; each value
/// carries its numeral).
enum CountdownCount {
  three(3),
  two(2),
  one(1);

  const CountdownCount(this.value);

  /// The tick numeral.
  final int value;
}

/// CountdownRing — the Figma `CountdownRing` set (60:590); web sibling
/// `CountdownRing.tsx`. The MI-12 capture countdown: the ring arc holds
/// the remaining fraction (count/3), the numeral pops per tick
/// (entrance/standard motion tokens; reduced motion swaps the numeral
/// only). Salvages the legacy `countdown.dart` Animation-driven idea —
/// the C6 screen drives ticks and rebuilds with the next [count].
///
/// On-media capture UI: the raw #FFFFFF ring/numeral over the camera feed
/// is the documented token exception (c-series inventory).
class CountdownRing extends StatelessWidget {
  const CountdownRing({required this.count, this.size = 96, super.key});

  final CountdownCount count;

  /// Ring diameter (Figma master: 96).
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = theme.extension<AppMotion>()!;
    final typography = theme.extension<AppTypography>()!;

    // On-media white — documented exception, never a theme token.
    const onMediaWhite = Color(0xFFFFFFFF);

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Capturing in ${count.value}',
      // The numeral/ring are presentational — the label carries the tick.
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                // The arc animates toward the remaining fraction per tick
                // (slow/standard tokens); a fixed tween end keeps a single
                // build deterministic for goldens.
                tween: Tween<double>(
                  begin: count.value / 3,
                  end: count.value / 3,
                ),
                duration: motion.slow,
                curve: motion.standardEasing,
                builder: (context, fraction, _) => CustomPaint(
                  painter: _RingPainter(fraction: fraction),
                ),
              ),
            ),
            // The numeral pops per tick (scale 0.8 → 1, entrance token).
            TweenAnimationBuilder<double>(
              key: ValueKey<int>(count.value),
              tween: Tween<double>(begin: 0.8, end: 1),
              duration: motion.entrance,
              curve: motion.standardEasing,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                '${count.value}',
                style: typography.display32Bold.copyWith(
                  color: onMediaWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction});

  final double fraction;

  static const Color _onMediaWhite = Color(0xFFFFFFFF);
  static const double _stroke = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas
      // Track: 25%-opacity white ring.
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = _onMediaWhite.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke,
      )
      // Arc: the remaining fraction, from 12 o'clock.
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = _onMediaWhite
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
