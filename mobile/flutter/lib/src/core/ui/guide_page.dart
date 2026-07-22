import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The Figma `GuidePage` set's `step` axis (526:33) — the C6 guide's five
/// canvas-first pages (M-8/M-10: pose split 2026-07-22).
enum GuideStep { intro, ready, setup, poseFront, poseSide }

/// GuidePage — the Figma `GuidePage` set (526:33); mobile-first (no web
/// sibling — the Figma master is the only reference). ONE parameterized
/// page: an illustration card (`bg-elev` fill, 1px `border` stroke,
/// radius 8, 358×268 design space) recomposing the Capture Kit
/// silhouette + diagram vectors in token colors — dashed `text-2`
/// silhouettes, accent-gradient measure lines, phone/distance/light
/// diagrams, accent corner marks + 45° rays — over a Title/20 Semi Bold +
/// Body/14 `text-2` copy block. Replaces the 2023 navy photo art
/// (guide1/guide3/guide4/guide5/step2, deleted with this rebuild); page
/// dots and the gradient CTA stay frame-level in `guide_screen.dart`.
class GuidePage extends StatelessWidget {
  const GuidePage({
    required this.step,
    required this.title,
    required this.bullets,
    super.key,
  });

  /// Picks the illustration; copy arrives from the caller's ARB keys
  /// (the canvas strings are the canon — c-series ledger).
  final GuideStep step;

  final String title;
  final List<String> bullets;

  /// The Figma illustration design space (all vector geometry below is
  /// authored in these coordinates).
  static const Size _designSize = Size(358, 268);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: colors.bgElev,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(radii.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: _designSize.width / _designSize.height,
            child: FittedBox(
              child: SizedBox.fromSize(
                size: _designSize,
                child: _Illustration(step: step),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: typography.title20SemiBold.copyWith(color: colors.text),
        ),
        const SizedBox(height: 12),
        for (final (index, bullet) in bullets.indexed) ...<Widget>[
          if (index > 0) const SizedBox(height: 8),
          Text(
            bullet,
            style: typography.body14.copyWith(color: colors.text2),
          ),
        ],
      ],
    );
  }
}

/// The per-step illustration: pure vectors paint in one CustomPaint
/// (token strokes); text-bearing elements (chips, dimension labels) stay
/// WIDGETS so themes and the golden text-blocking treat them like all
/// other text.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.step});

  final GuideStep step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(
          painter: switch (step) {
            GuideStep.intro => _IntroPainter(colors: colors),
            GuideStep.ready => _ReadyPainter(colors: colors),
            GuideStep.setup => _SetupPainter(colors: colors),
            GuideStep.poseFront => _PoseFrontPainter(colors: colors),
            GuideStep.poseSide => _PoseSidePainter(colors: colors),
          },
        ),
        ...switch (step) {
          GuideStep.intro => <Widget>[
            const _DiagramChip(left: 241, top: 119, label: 'Your height'),
          ],
          GuideStep.ready => <Widget>[
            const _DiagramChip(left: 233, top: 39, label: 'Tie hair back'),
            const _DiagramChip(left: 23, top: 95, label: 'Fitted clothes'),
            const _DiagramChip(left: 255, top: 195, label: 'Bare feet'),
          ],
          GuideStep.setup => <Widget>[
            _DiagramLabel(
              left: 159,
              top: 241,
              label: '5–6 ft',
              color: colors.text2,
            ),
          ],
          GuideStep.poseFront => <Widget>[
            _DiagramLabel(
              left: 225,
              top: 143,
              label: '45°',
              color: colors.accentText,
            ),
          ],
          GuideStep.poseSide => const <Widget>[],
        },
      ],
    );
  }
}

/// The illustration callout chip (`bg` fill, `border` stroke, pill —
/// Micro/12 Semi Bold `text-2`).
class _DiagramChip extends StatelessWidget {
  const _DiagramChip({
    required this.left,
    required this.top,
    required this.label,
  });

  final double left;
  final double top;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.bg,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(radii.pill),
        ),
        child: Text(
          label,
          style: typography.micro12.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.text2,
          ),
        ),
      ),
    );
  }
}

/// A bare dimension label (Micro/12 Semi Bold) — "5–6 ft", "45°".
class _DiagramLabel extends StatelessWidget {
  const _DiagramLabel({
    required this.left,
    required this.top,
    required this.label,
    required this.color,
  });

  final double left;
  final double top;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Positioned(
      left: left,
      top: top,
      child: Text(
        label,
        style: typography.micro12.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters — geometry transcribed from the Figma vectors (526:33), design
// space 358×268. Shared dashed-silhouette clone at three scales.
// ---------------------------------------------------------------------------

/// The dashed front silhouette (Capture Kit clone) in its own 91.3×210
/// box — head, trunk, arms slightly out, legs; the guide art's base
/// figure. [scale]/[offset] place the box in the card's design space.
void _paintFrontSilhouette(
  Canvas canvas,
  Paint paint, {
  required Offset offset,
  double scale = 1,
}) {
  Offset at(double x, double y) => offset + Offset(x * scale, y * scale);
  final head = Path()
    ..addOval(
      Rect.fromCircle(center: at(45.65, 16.43), radius: 10.96 * scale),
    );
  final trunk = Path()
    ..moveTo(at(31.04, 42).dx, at(31.04, 42).dy)
    ..cubicTo(
      at(38.35, 34.7).dx,
      at(38.35, 34.7).dy,
      at(52.96, 34.7).dx,
      at(52.96, 34.7).dy,
      at(60.26, 42).dx,
      at(60.26, 42).dy,
    )
    ..lineTo(at(63, 95.87).dx, at(63, 95.87).dy)
    ..cubicTo(
      at(63, 109.57).dx,
      at(63, 109.57).dy,
      at(56.61, 117.78).dx,
      at(56.61, 117.78).dy,
      at(45.65, 117.78).dx,
      at(45.65, 117.78).dy,
    )
    ..cubicTo(
      at(34.7, 117.78).dx,
      at(34.7, 117.78).dy,
      at(28.3, 109.57).dx,
      at(28.3, 109.57).dy,
      at(28.3, 95.87).dx,
      at(28.3, 95.87).dy,
    )
    ..close();
  final limbs = Path()
    ..moveTo(at(28.3, 45.65).dx, at(28.3, 45.65).dy)
    ..lineTo(at(17.35, 84.91).dx, at(17.35, 84.91).dy)
    ..moveTo(at(63, 45.65).dx, at(63, 45.65).dy)
    ..lineTo(at(73.96, 84.91).dx, at(73.96, 84.91).dy)
    ..moveTo(at(38.35, 117.78).dx, at(38.35, 117.78).dy)
    ..lineTo(at(35.61, 196.3).dx, at(35.61, 196.3).dy)
    ..moveTo(at(52.96, 117.78).dx, at(52.96, 117.78).dy)
    ..lineTo(at(55.7, 196.3).dx, at(55.7, 196.3).dy);
  for (final path in <Path>[head, trunk, limbs]) {
    canvas.drawPath(
      _dashPath(path, dash: 5 * scale, gap: 4 * scale),
      paint,
    );
  }
}

/// Guide-art dashed stroke over `text-2` — the diagram figure tone.
Paint _figurePaint(AppColors colors, {double strokeWidth = 1.37}) => Paint()
  ..color = colors.text2
  ..style = PaintingStyle.stroke
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// step=intro (524:1583): silhouette + three accent-gradient measure
/// lines + the height double-arrow ("Your height" chip is a widget).
class _IntroPainter extends CustomPainter {
  const _IntroPainter({required this.colors});

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    _paintFrontSilhouette(
      canvas,
      _figurePaint(colors),
      offset: const Offset(63, 28),
    );

    // Measure lines — accent gradient, 3px, radius 1.5.
    for (final top in const <double>[84, 114, 141]) {
      final rect = Rect.fromLTWH(37, top, 150, 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[colors.accentStart, colors.accentEnd],
          ).createShader(rect),
      );
    }

    // Height arrow — double-headed with end caps (22×198 at 238,34).
    final paint = Paint()
      ..color = colors.text2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const dx = 238.0;
    const dy = 34.0;
    final arrow = Path()
      ..moveTo(dx + 11, dy + 5)
      ..lineTo(dx + 11, dy + 193)
      ..moveTo(dx + 17, dy + 13)
      ..lineTo(dx + 11, dy + 5)
      ..lineTo(dx + 5, dy + 13)
      ..moveTo(dx + 17, dy + 185)
      ..lineTo(dx + 11, dy + 193)
      ..lineTo(dx + 5, dy + 185)
      ..moveTo(dx + 1, dy + 1)
      ..lineTo(dx + 21, dy + 1)
      ..moveTo(dx + 1, dy + 197)
      ..lineTo(dx + 21, dy + 197);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(_IntroPainter oldDelegate) => oldDelegate.colors != colors;
}

/// step=ready (524:1589): silhouette + the three dashed chip connectors
/// (the chips are widgets).
class _ReadyPainter extends CustomPainter {
  const _ReadyPainter({required this.colors});

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    _paintFrontSilhouette(
      canvas,
      _figurePaint(colors),
      offset: const Offset(132, 28),
    );

    final paint = Paint()
      ..color = colors.text2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    // Tie hair back ← head; Fitted clothes → trunk; Bare feet ← ankles.
    for (final (from, to) in <(Offset, Offset)>[
      (const Offset(229.75, 51.75), const Offset(195.75, 47.75)),
      (const Offset(133.75, 107.75), const Offset(157.75, 109.75)),
      (const Offset(251.75, 207.75), const Offset(189.75, 221.75)),
    ]) {
      canvas.drawPath(
        _dashPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..lineTo(to.dx, to.dy),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ReadyPainter oldDelegate) => oldDelegate.colors != colors;
}

/// step=setup (524:1596): ground line, accent phone + lens dot, the
/// distant silhouette, dashed sightline, 5–6 ft dimension, light glyph +
/// rays ("5–6 ft" text is a widget).
class _SetupPainter extends CustomPainter {
  const _SetupPainter({required this.colors});

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Ground.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(23, 218, 310, 2),
        const Radius.circular(1),
      ),
      Paint()..color = colors.border,
    );

    // Phone (accent stroke) + lens dot.
    final accentStroke = Paint()
      ..color = colors.accentStart
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(59, 183, 20, 36),
          const Radius.circular(4),
        ),
        accentStroke,
      )
      ..drawCircle(
        const Offset(69, 191),
        2,
        Paint()..color = colors.accentStart,
      );

    // The distant subject — the same silhouette at 64% scale.
    _paintFrontSilhouette(
      canvas,
      _figurePaint(colors, strokeWidth: 0.88),
      offset: const Offset(251, 85),
      scale: 0.64,
    );

    // Camera sightline — 6/6 dash.
    final line = Paint()
      ..color = colors.text2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      _dashPath(
        Path()
          ..moveTo(81.75, 195.75)
          ..lineTo(269.75, 109.75),
        dash: 6,
        gap: 6,
      ),
      line,
    );

    // Distance dimension — end ticks + rail.
    final dimension = Path()
      ..moveTo(83.75, 233.75)
      ..lineTo(269.75, 233.75)
      ..moveTo(83.75, 229.75)
      ..lineTo(83.75, 237.75)
      ..moveTo(269.75, 229.75)
      ..lineTo(269.75, 237.75);
    canvas.drawPath(dimension, line);

    // Light — circle + rays.
    final light = Paint()
      ..color = colors.text2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(const Offset(178, 38), 8, light);
    final rays = Path()
      ..moveTo(179, 24)
      ..lineTo(179, 16)
      ..moveTo(194, 27)
      ..lineTo(200, 21)
      ..moveTo(164, 27)
      ..lineTo(158, 21)
      ..moveTo(196, 39)
      ..lineTo(204, 39)
      ..moveTo(162, 39)
      ..lineTo(154, 39);
    canvas.drawPath(rays, light);
  }

  @override
  bool shouldRepaint(_SetupPainter oldDelegate) => oldDelegate.colors != colors;
}

/// The accent viewfinder corner marks shared by the two pose steps —
/// 20×20 Ls at the four corners of the 87..269 × 9..257 frame, 3px round.
void _paintCornerMarks(Canvas canvas, AppColors colors) {
  final paint = Paint()
    ..color = colors.accentStart
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final marks = Path()
    ..moveTo(87, 29)
    ..lineTo(87, 9)
    ..lineTo(107, 9)
    ..moveTo(249, 9)
    ..lineTo(269, 9)
    ..lineTo(269, 29)
    ..moveTo(269, 237)
    ..lineTo(269, 257)
    ..lineTo(249, 257)
    ..moveTo(107, 257)
    ..lineTo(87, 257)
    ..lineTo(87, 237);
  canvas.drawPath(marks, paint);
}

/// step=pose-front (524:1604): corner marks + the 110% silhouette + the
/// accent 45° arm rays + feet-apart dimension ("45°" text is a widget).
class _PoseFrontPainter extends CustomPainter {
  const _PoseFrontPainter({required this.colors});

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    _paintCornerMarks(canvas, colors);

    _paintFrontSilhouette(
      canvas,
      _figurePaint(colors, strokeWidth: 1.51),
      offset: const Offset(127, 17),
      scale: 1.1,
    );

    // 45° arm rays — accent dashed; feet-apart dimension — ticks +
    // dashed gap.
    final accent = Paint()
      ..color = colors.accentStart
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = colors.text2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(
        _dashPath(
          Path()
            ..moveTo(158.75, 67.75)
            ..lineTo(138.75, 139.75)
            ..moveTo(198.75, 67.75)
            ..lineTo(218.75, 139.75),
        ),
        accent,
      )
      ..drawPath(
        Path()
          ..moveTo(164.75, 251.75)
          ..lineTo(164.75, 257.75)
          ..moveTo(193.75, 251.75)
          ..lineTo(193.75, 257.75),
        line,
      )
      ..drawPath(
        _dashPath(
          Path()
            ..moveTo(167.75, 254.75)
            ..lineTo(190.75, 254.75),
          dash: 3,
          gap: 3,
        ),
        line,
      );
  }

  @override
  bool shouldRepaint(_PoseFrontPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// step=pose-side (540:134): corner marks + the right-profile silhouette
/// (Capture Kit side clone) + the accent turn arrow over the head.
class _PoseSidePainter extends CustomPainter {
  const _PoseSidePainter({required this.colors});

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    _paintCornerMarks(canvas, colors);

    // Right-profile silhouette — 100.4×231 box at (127.7, 17).
    const dx = 127.7;
    const dy = 17.0;
    final paint = _figurePaint(colors, strokeWidth: 1.51);
    final head = Path()
      ..addOval(
        Rect.fromCircle(
          center: const Offset(dx + 53.3, dy + 18.1),
          radius: 12.05,
        ),
      );
    final trunk = Path()
      ..moveTo(dx + 39.21, dy + 46.19)
      ..cubicTo(
        dx + 44.77,
        dy + 38.14,
        dx + 55.88,
        dy + 38.14,
        dx + 61.44,
        dy + 46.19,
      )
      ..lineTo(dx + 63.53, dy + 105.63)
      ..cubicTo(
        dx + 63.53,
        dy + 120.73,
        dx + 58.66,
        dy + 129.8,
        dx + 50.33,
        dy + 129.8,
      )
      ..cubicTo(
        dx + 41.99,
        dy + 129.8,
        dx + 37.13,
        dy + 120.73,
        dx + 37.13,
        dy + 105.63,
      )
      ..close();
    final armAndLegs = Path()
      // The hanging near arm (arms relaxed — the side pose's rule).
      ..moveTo(dx + 50.33, dy + 52.25)
      ..lineTo(dx + 50.33, dy + 115.5)
      // Overlapped legs.
      ..moveTo(dx + 48.11, dy + 129.56)
      ..lineTo(dx + 45.1, dy + 215.94)
      ..moveTo(dx + 50.6, dy + 129.56)
      ..lineTo(dx + 53.61, dy + 215.94);
    for (final path in <Path>[head, trunk, armAndLegs]) {
      canvas.drawPath(_dashPath(path, dash: 5.5, gap: 4.4), paint);
    }

    // Turn arrow — accent dashed arc with arrowhead (56×14 at 149,7).
    final accent = Paint()
      ..color = colors.accentStart
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final arrow = Path()
      ..moveTo(149.75, 21.75)
      ..cubicTo(164.75, 7.75, 191.75, 7.75, 205.75, 15.75)
      ..moveTo(196.75, 19.75)
      ..lineTo(205.75, 15.75)
      ..lineTo(198.75, 7.75);
    canvas.drawPath(_dashPath(arrow), accent);
  }

  @override
  bool shouldRepaint(_PoseSidePainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// Dash pattern along a path (the Capture Kit dash helper).
Path _dashPath(Path source, {double dash = 4, double gap = 4}) {
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
