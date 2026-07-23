import 'dart:async' show unawaited;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The MI-14 timeline dot ladder — done (success fill), current (gradient
/// + pulse), upcoming (hairline ring) and the terminal-error rung the C8
/// timeline was missing (D41: declined/disputed/refunded/cancelled must
/// not wear a green ✓).
enum TimelineDotState { done, current, upcoming, terminalError }

/// TimelineConnector — the MI-14 timeline segment (design.md §4: "timeline
/// dot draws its connector line 400ms"): one 14px dot plus (unless
/// [last]) the 2px connector below it, which draws top-to-bottom over
/// 400ms on mount. The `current` dot carries a soft repeating pulse
/// (scale 1→1.06→1 — the §4 pulse shape).
///
/// Sized by its parent: the connector expands to fill the available
/// height (the C8 rows drive height via [IntrinsicHeight]). 400ms is the
/// §4 exact value; easing rides the token curves. Reduced motion renders
/// the connector fully drawn and the pulse still (design.md §5).
class TimelineConnector extends StatefulWidget {
  const TimelineConnector({
    required this.state,
    this.last = false,
    super.key,
  });

  /// The §4 connector draw duration — exact MI value.
  static const Duration drawDuration = Duration(milliseconds: 400);

  final TimelineDotState state;

  /// True for the final row — no connector below the dot.
  final bool last;

  @override
  State<TimelineConnector> createState() => _TimelineConnectorState();
}

class _TimelineConnectorState extends State<TimelineConnector>
    with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: TimelineConnector.drawDuration,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      _draw.value = 1;
      _pulse
        ..stop()
        ..value = 0;
      return;
    }
    if (!_draw.isAnimating && _draw.value == 0) {
      unawaited(
        _draw.animateTo(
          1,
          curve: Theme.of(context).extension<AppMotion>()!.standardEasing,
        ),
      );
    }
    _syncPulse();
  }

  @override
  void didUpdateWidget(TimelineConnector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncPulse();
  }

  void _syncPulse() {
    final pulsing =
        widget.state == TimelineDotState.current &&
        !MediaQuery.disableAnimationsOf(context);
    if (pulsing) {
      if (!_pulse.isAnimating) unawaited(_pulse.repeat(reverse: true));
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final dot = switch (widget.state) {
      TimelineDotState.done => _dot(color: colors.success),
      TimelineDotState.current => _dot(gradient: colors.accentGradient),
      TimelineDotState.upcoming => _dot(ring: colors.border),
      TimelineDotState.terminalError => _dot(color: colors.error),
    };

    return Column(
      children: <Widget>[
        if (widget.state == TimelineDotState.current)
          ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1.06).animate(
              CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            ),
            child: dot,
          )
        else
          dot,
        if (!widget.last)
          Expanded(
            // MI-14: the connector draws downward from the dot — the
            // line grows 0→full, anchored top. Painted (never sized)
            // because the C8 rows measure via IntrinsicHeight: a
            // FractionallySizedBox at heightFactor 0 reports an INFINITE
            // max intrinsic height (child ÷ 0) and crashes the row.
            child: SizedBox(
              width: 2,
              child: AnimatedBuilder(
                animation: _draw,
                builder: (context, _) => CustomPaint(
                  painter: ConnectorDrawPainter(
                    color: colors.border,
                    progress: _draw.value,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dot({Color? color, Gradient? gradient, Color? ring}) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: color,
      gradient: gradient,
      shape: BoxShape.circle,
      border: ring == null ? null : Border.all(color: ring, width: 2),
    ),
  );
}

/// The MI-14 connector line at draw [progress] (0 → 1, anchored top).
/// Public so the unit suite can read the draw state off the render tree.
class ConnectorDrawPainter extends CustomPainter {
  const ConnectorDrawPainter({required this.color, required this.progress});

  final Color color;

  /// Fraction of the connector's span drawn so far.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * progress),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(ConnectorDrawPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
