import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/flip_unit_toggle.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ManualMeasureRow — the Figma `ManualMeasureRow` set (66:695); web
/// sibling `ManualMeasureRow.tsx`. Axes: `state` default/active/error
/// (border binds border/accent-start/error). MI-13: tape-measure slider
/// (tick ruler + accent thumb) + numeric field + cm/in toggle (the
/// 200ms x-rotation flip rides the shared [FlipUnitToggle]) + the
/// sparkline preview animating on value change when [history] is
/// provided. The value is canonical cm; the display converts.
/// Out-of-range renders a double-check hint, never a hard block
/// (c-series inventory note) — [error] is advisory copy from the
/// consumer's sanity range (flows/vault.md §2).
class ManualMeasureRow extends StatelessWidget {
  const ManualMeasureRow({
    required this.name,
    required this.valueCm,
    required this.onChanged,
    required this.unit,
    required this.onUnitChanged,
    this.min = 10,
    this.max = 200,
    this.history = const <double>[],
    this.error,
    this.active = false,
    super.key,
  });

  /// Measurement name, e.g. `shoulder_width` — label renders humanized.
  final String name;

  final double? valueCm;
  final ValueChanged<double?> onChanged;

  final MeasureUnit unit;
  final ValueChanged<MeasureUnit> onUnitChanged;

  /// Sanity range in cm (slider bounds).
  final double min;
  final double max;

  /// Prior session values (oldest → newest, canonical cm) — non-empty
  /// renders the MI-13 sparkline preview: the entered value becomes the
  /// line's animated last point.
  final List<double> history;

  /// The `error` state — advisory double-check copy.
  final String? error;

  /// The `active` state (row currently being edited).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final motion = theme.extension<AppMotion>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final borderColor = error != null
        ? colors.error
        : active
        ? colors.accentStart
        : colors.border;

    final display = valueCm == null
        ? ''
        : unit == MeasureUnit.cm
        ? _trim((valueCm! * 10).round() / 10)
        : _trim((valueCm! / cmPerInch * 10).round() / 10);

    return AnimatedContainer(
      duration: motion.fast,
      curve: motion.standardEasing,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  humanizeMeasureName(name),
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ValueField(
                display: display,
                unit: unit,
                semanticLabel: '${humanizeMeasureName(name)} value',
                onSubmitted: (raw) => onChanged(_parse(raw)),
                onUnitChanged: onUnitChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tape-measure ruler (Figma 66:695): tick marks under a
          // transparent track, accent-dot thumb. Bespoke (not Material
          // Slider) — the master's ruler look, no overlay machinery.
          _TapeSlider(
            semanticLabel: '${humanizeMeasureName(name)} slider',
            value: (valueCm ?? min).clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            tickColor: colors.text2.withValues(alpha: 0.6),
            thumbColor: colors.accentStart,
          ),
          if (history.isNotEmpty && valueCm != null) ...<Widget>[
            const SizedBox(height: 8),
            // MI-13: the sparkline preview — prior sessions' values with
            // the entered value as the animated last point.
            Align(
              alignment: Alignment.centerRight,
              child: _PreviewSparkline(
                history: history,
                valueCm: valueCm!,
                stroke: colors.accentStart,
                endDot: colors.accentEnd,
              ),
            ),
          ],
          if (error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              error!,
              style: typography.micro12.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }

  double? _parse(String raw) {
    if (raw.trim().isEmpty) return null;
    final number = double.tryParse(raw);
    if (number == null) return valueCm;
    return unit == MeasureUnit.cm ? number : number * cmPerInch;
  }

  static String _trim(double value) => value == value.truncateToDouble()
      ? value.truncate().toString()
      : value.toString();
}

/// Compact numeric field with the trailing cm/in toggle (MI-13 flip).
class _ValueField extends StatefulWidget {
  const _ValueField({
    required this.display,
    required this.unit,
    required this.semanticLabel,
    required this.onSubmitted,
    required this.onUnitChanged,
  });

  final String display;
  final MeasureUnit unit;
  final String semanticLabel;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<MeasureUnit> onUnitChanged;

  @override
  State<_ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<_ValueField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.display,
  );

  @override
  void didUpdateWidget(_ValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.display != oldWidget.display &&
        widget.display != _controller.text) {
      _controller.text = widget.display;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final nextUnit = widget.unit == MeasureUnit.cm
        ? MeasureUnit.inch
        : MeasureUnit.cm;

    return Container(
      width: 144,
      height: 40,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(radii.card),
        color: colors.bgElev,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              label: widget.semanticLabel,
              textField: true,
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: typography.body14.copyWith(
                  color: colors.text,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
                onSubmitted: widget.onSubmitted,
                onTapOutside: (_) {
                  widget.onSubmitted(_controller.text);
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ),
          ),
          Semantics(
            // Own node; the visible cm/in text is presentational — the
            // label names the action (named-control canon).
            container: true,
            excludeSemantics: true,
            label: 'Switch to ${nextUnit == MeasureUnit.cm ? 'cm' : 'in'}',
            button: true,
            child: InkResponse(
              onTap: () => widget.onUnitChanged(nextUnit),
              radius: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                // MI-13: the label flips with the 200ms x-rotation
                // (shared primitive — keyed by unit so the switcher
                // sees the swap).
                child: FlipUnitToggle(
                  child: Text(
                    widget.unit == MeasureUnit.cm ? 'cm' : 'in',
                    key: ValueKey<MeasureUnit>(widget.unit),
                    style: typography.micro12.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.text2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The MI-13 tape slider — 41-tick ruler strip with an accent-dot thumb,
/// dragged/tapped in 0.5cm steps.
class _TapeSlider extends StatelessWidget {
  const _TapeSlider({
    required this.semanticLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.tickColor,
    required this.thumbColor,
  });

  final String semanticLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double?> onChanged;
  final Color tickColor;
  final Color thumbColor;

  void _handle(BuildContext context, Offset localPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final fraction = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    // 0.5cm steps (the web sibling's `step=0.5`).
    final raw = min + fraction * (max - min);
    onChanged((raw * 2).round() / 2);
  }

  /// The assistive-technology step (one slider tick — the same 0.5cm the
  /// drag snaps to); mirrors the web sibling's keyboard-operable
  /// `input[type=range]`.
  void _step(double direction) =>
      onChanged((value + direction * 0.5).clamp(min, max));

  @override
  Widget build(BuildContext context) {
    final fraction = max == min ? 0.0 : (value - min) / (max - min);
    return Semantics(
      label: semanticLabel,
      slider: true,
      value: value.toStringAsFixed(1),
      increasedValue: (value + 0.5).clamp(min, max).toStringAsFixed(1),
      decreasedValue: (value - 0.5).clamp(min, max).toStringAsFixed(1),
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _handle(context, details.localPosition),
        onHorizontalDragUpdate: (details) =>
            _handle(context, details.localPosition),
        child: SizedBox(
          height: 24,
          width: double.infinity,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _TickRulerPainter(color: tickColor),
                ),
              ),
              Align(
                alignment: Alignment(2 * fraction - 1, 0),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The MI-13 sparkline preview — a 96×20 polyline of the metric's prior
/// sessions with the entered value as the last point, which TWEENS to
/// each new value (design.md §4: "value change animates sparkline
/// preview"). Reduced motion snaps.
class _PreviewSparkline extends StatelessWidget {
  const _PreviewSparkline({
    required this.history,
    required this.valueCm,
    required this.stroke,
    required this.endDot,
  });

  final List<double> history;
  final double valueCm;
  final Color stroke;
  final Color endDot;

  @override
  Widget build(BuildContext context) {
    final motion = Theme.of(context).extension<AppMotion>()!;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: valueCm),
      duration: reducedMotion ? Duration.zero : motion.base,
      curve: motion.standardEasing,
      builder: (context, animated, _) => CustomPaint(
        size: const Size(96, 20),
        painter: _PreviewSparklinePainter(
          values: <double>[...history, animated],
          stroke: stroke,
          endDot: endDot,
        ),
      ),
    );
  }
}

/// The MeasurementCard sparkline idiom at preview scale: 2px vertical
/// inset, accent-start stroke 1.5, accent-end end dot.
class _PreviewSparklinePainter extends CustomPainter {
  const _PreviewSparklinePainter({
    required this.values,
    required this.stroke,
    required this.endDot,
  });

  final List<double> values;
  final Color stroke;
  final Color endDot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1.0 : max - min;
    final step = size.width / (values.length - 1);

    Offset point(int i) => Offset(
      i * step,
      size.height - 2 - ((values[i] - min) / range) * (size.height - 4),
    );

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(
        point(values.length - 1),
        2.5,
        Paint()..color = endDot,
      );
  }

  @override
  bool shouldRepaint(_PreviewSparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.stroke != stroke ||
      oldDelegate.endDot != endDot;
}

/// 41 tick marks, every fifth tall (the web sibling's ruler strip).
class _TickRulerPainter extends CustomPainter {
  const _TickRulerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const count = 41;
    const inset = 4.0;
    final step = (size.width - 2 * inset) / (count - 1);
    for (var i = 0; i < count; i++) {
      final x = inset + i * step;
      final tall = i % 5 == 0;
      final height = tall ? 12.0 : 6.0;
      canvas.drawLine(
        Offset(x, size.height / 2 + height / 2),
        Offset(x, size.height / 2 - height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickRulerPainter oldDelegate) =>
      oldDelegate.color != color;
}
