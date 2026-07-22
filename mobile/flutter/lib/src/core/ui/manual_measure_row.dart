import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ManualMeasureRow — the Figma `ManualMeasureRow` set (66:695); web
/// sibling `ManualMeasureRow.tsx`. Axes: `state` default/active/error
/// (border binds border/accent-start/error). MI-13: tape-measure slider
/// (tick ruler + accent thumb) + numeric field + cm/in toggle. The value
/// is canonical cm; the display converts. Out-of-range renders a
/// double-check hint, never a hard block (c-series inventory note) —
/// [error] is advisory copy from the consumer's sanity range
/// (flows/vault.md §2).
class ManualMeasureRow extends StatelessWidget {
  const ManualMeasureRow({
    required this.name,
    required this.valueCm,
    required this.onChanged,
    required this.unit,
    required this.onUnitChanged,
    this.min = 10,
    this.max = 200,
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
          // transparent track, accent-dot thumb.
          SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TickRulerPainter(
                      color: colors.text2.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Semantics(
                  label: '${humanizeMeasureName(name)} slider',
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 0,
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      thumbColor: colors.accentStart,
                    ),
                    child: Slider(
                      value: (valueCm ?? min).clamp(min, max),
                      min: min,
                      max: max,
                      divisions: ((max - min) * 2).round(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                child: Text(
                  widget.unit == MeasureUnit.cm ? 'cm' : 'in',
                  style: typography.micro12.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text2,
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
