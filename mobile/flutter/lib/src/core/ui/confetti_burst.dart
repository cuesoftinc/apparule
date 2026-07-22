import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

/// ConfettiBurst — the MI-10 success burst (design.md §4: "confetti burst
/// ≤ 800ms (once per order)"): 28 pieces animate once from the
/// bottom-centre origin (the ✓ they celebrate) out to a deterministic
/// scatter, rotating and easing out over 800ms, then hold.
///
/// The END state reproduces the canvas frame's fixed-seed static scatter
/// byte-for-byte, so settled screens (and settling goldens) render the
/// ratified layout. [frozen] is the golden-freeze flag: skip the
/// animation and paint the settled scatter immediately — golden suites
/// pin it, and reduced motion implies it (design.md §5).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    required this.colors,
    this.frozen = false,
    this.child,
    super.key,
  });

  /// The §4 burst budget — exact MI value.
  static const Duration duration = Duration(milliseconds: 800);

  /// Piece colors, cycled across the 28 pieces.
  final List<Color> colors;

  /// Golden-freeze flag: paint the settled scatter with no animation.
  final bool frozen;

  /// Painted behind the scatter (the C5 success ✓).
  final Widget? child;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: ConfettiBurst.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.frozen || MediaQuery.disableAnimationsOf(context)) {
      _burst.value = 1;
    } else {
      unawaited(_burst.animateTo(1, curve: Curves.decelerate));
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _burst,
      builder: (context, child) => CustomPaint(
        painter: _ConfettiPainter(colors: widget.colors, t: _burst.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// The deterministic scatter painter: a fixed-seed LCG lays out the same
/// 28 pieces on every platform (the pre-animation static painter's exact
/// layout at `t == 1`); `t < 1` interpolates each piece from the
/// bottom-centre origin with a spin.
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.colors, required this.t});

  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    // Linear congruential generator with a fixed seed — same scatter on
    // every frame and every platform.
    var state = 0x5eed;
    double next() {
      state = (state * 48271) % 0x7fffffff;
      return (state % 1000) / 1000;
    }

    final origin = Offset(size.width / 2, size.height);
    for (var i = 0; i < 28; i++) {
      final x = next() * size.width;
      final y = next() * size.height * 0.8;
      final angle = next() * 3.14159;
      final color = colors[i % colors.length];
      final position = Offset.lerp(origin, Offset(x, y), t)!;
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        // One extra half-turn on the way out; lands on the scatter angle.
        ..rotate(angle + (1 - t) * 3.14159)
        ..drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -4, 8, 8),
            const Radius.circular(1.5),
          ),
          Paint()..color = color,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.t != t;
}
