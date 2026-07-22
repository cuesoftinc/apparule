import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_haptics.dart';
import 'package:flutter/material.dart';

/// GradientRefreshSpinner — the MI-5 pull-to-refresh (design.md §4:
/// "gradient spinner grows with pull distance (threshold 72px), haptic on
/// trigger") as a shared primitive.
///
/// Wraps a scrollable [child] that overscrolls at the top (give it
/// `EdgeResistPhysics`/bouncing physics); the gradient arc grows with the
/// pull, and releasing at/past [threshold] fires [AppHaptics.light] and
/// runs [onRefresh] while the spinner rotates.
class GradientRefreshSpinner extends StatefulWidget {
  const GradientRefreshSpinner({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// The MI-5 trigger distance — §4 exact value.
  static const double threshold = 72;

  /// The refresh action; the spinner rotates until it settles.
  final Future<void> Function() onRefresh;

  /// A vertically scrollable that can overscroll its top edge.
  final Widget child;

  @override
  State<GradientRefreshSpinner> createState() => _GradientRefreshSpinnerState();
}

class _GradientRefreshSpinnerState extends State<GradientRefreshSpinner> {
  double _pull = 0;
  bool _dragging = false;
  bool _refreshing = false;

  bool _handleNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    switch (notification) {
      case ScrollStartNotification(:final dragDetails):
        _dragging = dragDetails != null;
      case ScrollUpdateNotification(:final metrics, :final dragDetails):
        final pull = metrics.pixels < 0 ? -metrics.pixels : 0.0;
        if (dragDetails == null && _dragging) {
          // The finger just lifted — the release decides the trigger.
          _dragging = false;
          _maybeTrigger();
        } else if (dragDetails != null) {
          _dragging = true;
        }
        if (pull != _pull) setState(() => _pull = pull);
      case ScrollEndNotification():
        if (_dragging) {
          _dragging = false;
          _maybeTrigger();
        }
      default:
        break;
    }
    return false;
  }

  void _maybeTrigger() {
    if (_refreshing || _pull < GradientRefreshSpinner.threshold) return;
    setState(() => _refreshing = true);
    // MI-5 + MI-20: haptic on trigger.
    AppHaptics.light();
    // runAction is the screens' seam; the spinner just settles — refresh
    // failure states belong to the wrapped surface.
    unawaited(
      Future<void>(() async {
        try {
          await widget.onRefresh();
        } finally {
          if (mounted) setState(() => _refreshing = false);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pull / GradientRefreshSpinner.threshold).clamp(0.0, 1.0);
    final visible = _refreshing || progress > 0;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: Stack(
        children: <Widget>[
          widget.child,
          if (visible)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: GradientSpinnerIndicator(
                  progress: _refreshing ? 1 : progress,
                  spinning: _refreshing,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The drawn indicator: a 28px gradient arc whose sweep and opacity grow
/// with [progress] (0..1 of the 72px threshold); [spinning] rotates it
/// while a refresh is in flight. Public so goldens can pin the visual
/// states without a scrollable harness.
class GradientSpinnerIndicator extends StatefulWidget {
  const GradientSpinnerIndicator({
    required this.progress,
    this.spinning = false,
    super.key,
  });

  /// Pull progress toward the threshold, 0..1 — drives sweep + opacity.
  final double progress;

  /// True while the refresh future is pending.
  final bool spinning;

  @override
  State<GradientSpinnerIndicator> createState() =>
      _GradientSpinnerIndicatorState();
}

class _GradientSpinnerIndicatorState extends State<GradientSpinnerIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  @override
  void didUpdateWidget(GradientSpinnerIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spinning != widget.spinning) _syncSpin();
  }

  void _syncSpin() {
    if (widget.spinning) {
      unawaited(_rotation.repeat());
    } else {
      _rotation
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final progress = widget.progress.clamp(0.0, 1.0);

    return Opacity(
      opacity: widget.spinning ? 1 : progress,
      child: RotationTransition(
        turns: _rotation,
        child: CustomPaint(
          size: const Size.square(28),
          painter: _GradientArcPainter(
            start: colors.accentStart,
            end: colors.accentEnd,
            // The arc grows with the pull; a full spinner keeps the MI-8
            // ring's open tail so the rotation reads.
            sweep: progress * math.pi * 1.5,
          ),
        ),
      ),
    );
  }
}

class _GradientArcPainter extends CustomPainter {
  const _GradientArcPainter({
    required this.start,
    required this.end,
    required this.sweep,
  });

  final Color start;
  final Color end;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    if (sweep <= 0) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: <Color>[start, end],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect.deflate(2), -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_GradientArcPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.end != end ||
      oldDelegate.sweep != sweep;
}
