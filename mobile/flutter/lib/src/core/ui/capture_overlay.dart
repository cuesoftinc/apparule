import 'dart:async';

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:flutter/material.dart';

/// The Figma `CaptureOverlay` set's `guide` axis (63:701).
enum CaptureGuide { searching, aligned, countdown, qcHint }

/// CaptureOverlay — the Figma `CaptureOverlay` set (63:701); web sibling
/// `CaptureOverlay.tsx`. Guide states: searching (silhouette pulses
/// gently, MI-12) / aligned (guide turns success, "Perfect — hold still")
/// / countdown (CountdownRing slot) / qc-hint (QCHintChip slot,
/// first-failure-only). 9:16 viewport, 40% scrim, viewfinder corner
/// marks, top instruction line.
///
/// On-media capture UI: raw #FFFFFF for the guide text/marks/silhouette
/// over the camera feed is the documented token exception (c-series
/// inventory).
class CaptureOverlay extends StatelessWidget {
  const CaptureOverlay({
    required this.guide,
    this.countdown = CountdownCount.three,
    this.qcCode,
    this.child,
    super.key,
  });

  final CaptureGuide guide;

  /// `countdown` guide: the current tick.
  final CountdownCount countdown;

  /// `qc-hint` guide: the fail code to surface (first failure only).
  final QcFailCode? qcCode;

  /// The camera viewport (preview/photo); fills the frame behind the
  /// guide.
  final Widget? child;

  static const Color _onMediaWhite = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radii.card),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: LayoutBuilder(
          builder: (context, viewport) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(color: Color(0xFF000000)),
              ?child,
              // 40% scrim.
              const ColoredBox(color: Color(0x66000000)),
              // Viewfinder corner marks.
              const Positioned.fill(
                child: CustomPaint(painter: _CornerMarksPainter()),
              ),
              // Instruction line — 16px semibold white, top-centred (9%).
              Positioned(
                left: 16,
                right: 16,
                top: viewport.maxHeight * 0.09,
                child: Text(
                  guide == CaptureGuide.aligned
                      ? 'Perfect — hold still'
                      : 'Stand inside the outline',
                  textAlign: TextAlign.center,
                  style: typography.body16SemiBold.copyWith(
                    color: _onMediaWhite,
                  ),
                ),
              ),
              // Standing silhouette (head → shoulders → arms-out →
              // ankles), 70% of the viewport height; dashed while
              // searching, solid success stroke when aligned (MI-12).
              Center(
                child: SizedBox(
                  height: viewport.maxHeight * 0.7,
                  child: AspectRatio(
                    aspectRatio: 200 / 300,
                    child: _PulsingSilhouette(
                      pulsing: guide == CaptureGuide.searching,
                      color: guide == CaptureGuide.aligned
                          ? colors.success
                          : _onMediaWhite,
                      dashed: guide != CaptureGuide.aligned,
                    ),
                  ),
                ),
              ),
              if (guide == CaptureGuide.countdown)
                Center(child: CountdownRing(count: countdown)),
              if (guide == CaptureGuide.qcHint && qcCode != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Center(child: QCHintChip(code: qcCode!)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// MI-12: the silhouette pulses gently (2s ease-in-out) while searching;
/// reduced motion holds it at 70% opacity.
class _PulsingSilhouette extends StatefulWidget {
  const _PulsingSilhouette({
    required this.pulsing,
    required this.color,
    required this.dashed,
  });

  final bool pulsing;
  final Color color;
  final bool dashed;

  @override
  State<_PulsingSilhouette> createState() => _PulsingSilhouetteState();
}

class _PulsingSilhouetteState extends State<_PulsingSilhouette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_PulsingSilhouette oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final animate = widget.pulsing && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    } else if (!animate) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        // Pulse 0.7 → 1.0; static states hold 0.8 (web `opacity-80`).
        opacity: widget.pulsing ? 0.7 + 0.3 * _controller.value : 0.8,
        child: CustomPaint(
          painter: _SilhouettePainter(
            color: widget.color,
            dashed: widget.dashed,
          ),
        ),
      ),
    );
  }
}

/// The 200×300 guide-space silhouette path (web sibling's SVG, MI-12) —
/// head circle + torso/arms/legs path, 2.5 stroke, 6/6 dash when not
/// aligned.
class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 200;
    final scaleY = size.height / 300;
    canvas.scale(scaleX, scaleY);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 / scaleX
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final head = Path()
      ..addOval(Rect.fromCircle(center: const Offset(100, 38), radius: 22));
    final body = Path()
      // torso + arms slightly out (capture-qc.md arms clearance)
      ..moveTo(100, 60)
      ..cubicTo(78, 64, 68, 74, 66, 92)
      ..lineTo(46, 148)
      ..moveTo(100, 60)
      ..cubicTo(122, 64, 132, 74, 134, 92)
      ..lineTo(154, 148)
      ..moveTo(72, 88)
      ..cubicTo(72, 120, 76, 142, 80, 160)
      ..lineTo(76, 232)
      ..lineTo(72, 284)
      ..moveTo(128, 88)
      ..cubicTo(128, 120, 124, 142, 120, 160)
      ..lineTo(124, 232)
      ..lineTo(128, 284)
      ..moveTo(80, 160)
      ..cubicTo(92, 168, 108, 168, 120, 160);

    for (final path in <Path>[head, body]) {
      canvas.drawPath(dashed ? _dashPath(path) : path, paint);
    }
  }

  /// 6/6 dash pattern along the path.
  Path _dashPath(Path source) {
    const dash = 6.0;
    const gap = 6.0;
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dash + gap;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(_SilhouettePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}

/// The viewfinder corner marks (web sibling's 360×640 path) — raw white,
/// 3px stroke, round caps.
class _CornerMarksPainter extends CustomPainter {
  const _CornerMarksPainter();

  static const Color _onMediaWhite = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 360;
    final scaleY = size.height / 640;
    canvas.scale(scaleX, scaleY);

    final paint = Paint()
      ..color = _onMediaWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / scaleX
      ..strokeCap = StrokeCap.round;

    final marks = Path()
      ..moveTo(24, 56)
      ..lineTo(24, 32)
      ..lineTo(48, 32)
      ..moveTo(312, 32)
      ..lineTo(336, 32)
      ..lineTo(336, 56)
      ..moveTo(336, 584)
      ..lineTo(336, 608)
      ..lineTo(312, 608)
      ..moveTo(48, 608)
      ..lineTo(24, 608)
      ..lineTo(24, 584);
    canvas.drawPath(marks, paint);
  }

  @override
  bool shouldRepaint(_CornerMarksPainter oldDelegate) => false;
}
