import 'dart:async';

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:flutter/material.dart';

/// The Figma `CaptureOverlay` set's `guide` axis (63:701).
enum CaptureGuide { searching, aligned, countdown, qcHint }

/// CaptureOverlay — the Figma `CaptureOverlay` set (63:701); web sibling
/// `CaptureOverlay.tsx`. Guide states: searching (silhouette pulses
/// gently, MI-12) / aligned (guide turns success, "Perfect — hold still")
/// / countdown (CountdownRing slot) / qc-hint (QCHintChip slot,
/// first-failure-only). `pose` axis (M-10, side variant 539:2): the code
/// swaps the silhouette + hint per pose — front keeps the arms-out
/// outline, side draws the right-profile silhouette (head forward, single
/// hanging arm, overlapped legs) with "Turn your right side to the
/// camera". 9:16 viewport, 40% scrim, viewfinder corner marks, top
/// instruction line (y 112 of the 640 master — clears the over-media
/// pose bar, two-photo pass).
///
/// On-media capture UI: raw #FFFFFF for the guide text/marks/silhouette
/// over the camera feed is the documented token exception (c-series
/// inventory).
class CaptureOverlay extends StatelessWidget {
  const CaptureOverlay({
    required this.guide,
    this.pose = CapturePose.front,
    this.countdown = CountdownCount.three,
    this.qcCode,
    this.child,
    this.expand = false,
    super.key,
  });

  final CaptureGuide guide;

  /// The Figma `pose` axis — picks the silhouette and the instruction
  /// line (and the QC chip's pose-contextual `arms_position` copy).
  final CapturePose pose;

  /// Full-bleed screen use (the C6 camera frames 173:574/266:8419 run
  /// the viewport edge-to-edge): fills the parent instead of the 9:16
  /// card and drops the corner radius — the screen IS the viewport.
  final bool expand;

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

    final viewport = Stack(
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
        // Instruction line — 16px semibold white, top-centred at 17.5%
        // of the viewport (y 112 of the 640 master: moved down from y 72
        // in ALL variants to clear the over-media pose bar, two-photo
        // pass; Alignment y = 2·0.175 − 1).
        Align(
          alignment: const Alignment(0, -0.65),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              guide == CaptureGuide.aligned
                  ? 'Perfect — hold still'
                  : pose == CapturePose.side
                  ? 'Turn your right side to the camera'
                  : 'Stand inside the outline',
              textAlign: TextAlign.center,
              style: typography.body16SemiBold.copyWith(
                color: _onMediaWhite,
              ),
            ),
          ),
        ),
        // Standing silhouette, 70% of the viewport height; dashed while
        // searching, solid success stroke when aligned (MI-12). Front:
        // head → shoulders → arms-out → ankles; side (539:2): head
        // forward, narrow torso, single hanging arm, overlapped legs.
        Center(
          child: FractionallySizedBox(
            heightFactor: 0.7,
            child: AspectRatio(
              aspectRatio: 200 / 300,
              child: _PulsingSilhouette(
                pose: pose,
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
            // Centered regardless of code length (530:9017 — the master
            // pins the chip x; code centers it instead).
            child: Center(
              child: QCHintChip(code: qcCode!, pose: pose),
            ),
          ),
      ],
    );

    if (expand) return viewport;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radii.card),
      child: AspectRatio(aspectRatio: 9 / 16, child: viewport),
    );
  }
}

/// MI-12: the silhouette pulses gently (2s ease-in-out) while searching;
/// reduced motion holds it at 70% opacity.
class _PulsingSilhouette extends StatefulWidget {
  const _PulsingSilhouette({
    required this.pose,
    required this.pulsing,
    required this.color,
    required this.dashed,
  });

  final CapturePose pose;
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
      // Pulse 0.7 -> 1.0; static states hold 0.8 (web `opacity-80`).
      // Alpha rides the stroke color (not an Opacity layer) so the pulse
      // level survives alchemist's blocked-text golden pass.
      builder: (context, _) => CustomPaint(
        painter: _SilhouettePainter(
          pose: widget.pose,
          color: widget.color.withValues(
            alpha: widget.pulsing ? 0.7 + 0.3 * _controller.value : 0.8,
          ),
          dashed: widget.dashed,
        ),
      ),
    );
  }
}

/// The 200×300 guide-space silhouette paths (web sibling's SVG + the
/// 539:2 side variant, MI-12) — 2.5 stroke, 6/6 dash when not aligned.
class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter({
    required this.pose,
    required this.color,
    required this.dashed,
  });

  final CapturePose pose;
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

    for (final path in pose == CapturePose.front ? _front() : _side()) {
      canvas.drawPath(dashed ? _dashPath(path) : path, paint);
    }
  }

  /// Front: head circle + torso/arms-out/legs (capture-qc.md arms
  /// clearance).
  static List<Path> _front() {
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
    return <Path>[head, body];
  }

  /// Side (539:2): right profile — head slightly forward of the torso
  /// axis, one narrow torso capsule with the near arm hanging inside it,
  /// overlapped legs reading as a single dashed column.
  static List<Path> _side() {
    final head = Path()
      ..addOval(Rect.fromCircle(center: const Offset(102, 38), radius: 22));
    final torso = Path()
      // The foreshortened trunk — a tall capsule (not_side_profile's
      // passing shape: shoulders stacked in depth, not spread in x).
      ..moveTo(100, 62)
      ..cubicTo(112, 62, 118, 72, 118, 88)
      ..lineTo(116, 160)
      ..cubicTo(116, 176, 110, 184, 100, 184)
      ..cubicTo(90, 184, 84, 176, 84, 160)
      ..lineTo(82, 88)
      ..cubicTo(82, 72, 88, 62, 100, 62);
    final arm = Path()
      // The near arm hangs relaxed inside the trunk outline
      // (capture-qc.md side arms rule: wrists within 5% of the hips).
      ..moveTo(100, 78)
      ..lineTo(100, 168);
    final legs = Path()
      // Overlapped legs — two near-vertical lines close together.
      ..moveTo(97, 184)
      ..lineTo(93, 284)
      ..moveTo(103, 184)
      ..lineTo(107, 284);
    return <Path>[head, torso, arm, legs];
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
      oldDelegate.pose != pose ||
      oldDelegate.color != color ||
      oldDelegate.dashed != dashed;
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
