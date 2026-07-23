import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `MeasurementCard` set's `source` axis (48:208).
enum MeasurementSource { scan, manual }

/// MeasurementCard — the Figma `MeasurementCard` set (48:208); web sibling
/// `MeasurementCard.tsx`. Axes: `source` scan/manual · `confidence`
/// normal/low (<0.7 renders the warn chip; manual entries carry `null`
/// confidence, capture-qc.md §4) · `sparkline` true/false (bespoke
/// CustomPaint — no chart kits). Value text sets
/// `FontFeature.tabularFigures()` (tnum canon — the Figma masters still
/// miss the manual toggle; Flutter renders it regardless).
class MeasurementCard extends StatelessWidget {
  const MeasurementCard({
    required this.name,
    required this.valueCm,
    required this.source,
    this.unit = MeasureUnit.inch,
    this.confidence,
    this.history,
    this.updatedLabel,
    this.onTap,
    super.key,
  });

  /// Measurement name, e.g. `shoulder_width` — renders humanized.
  final String name;

  final double valueCm;
  final MeasureUnit unit;
  final MeasurementSource source;

  /// Per-measurement confidence (capture-qc.md §4); `< 0.7` renders the
  /// "Low confidence" chip. Manual entries pass `null`.
  final double? confidence;

  /// Oldest → newest values for the sparkline (omit to hide).
  final List<double>? history;

  /// Pre-formatted meta line ("Updated 12d ago" — social relative idiom,
  /// consumer-owned).
  final String? updatedLabel;

  /// Tap → history sheet (wired by the vault view).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final lowConfidence = confidence != null && confidence! < 0.7;
    final history = this.history;

    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElev,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(radii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Figma master: 13px text-2 metric name; neutral outlined
              // source chip with a 12px glyph + sentence-case label.
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      humanizeMeasureName(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.caption13.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(radii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          source == MeasurementSource.scan
                              ? LucideIcons.camera
                              : LucideIcons.pencil,
                          size: 12,
                          color: colors.text2,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          source == MeasurementSource.scan ? 'Scan' : 'Manual',
                          style: typography.micro12.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatCm(valueCm, unit),
                style: typography.title20SemiBold.copyWith(
                  color: colors.text,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              if (lowConfidence) ...<Widget>[
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: colors.warn.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(radii.pill),
                  ),
                  child: Text(
                    'Low confidence · ${confidence!.toStringAsFixed(2)}',
                    style: typography.micro12.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.warnText,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
              if (history != null && history.length > 1) ...<Widget>[
                const SizedBox(height: 4),
                // Bespoke sparkline — accent-gradient trend, 168×32.
                CustomPaint(
                  size: const Size(168, 32),
                  painter: _SparklinePainter(
                    values: history,
                    stroke: colors.accentStart,
                    endDot: colors.accentEnd,
                  ),
                ),
              ],
              if (updatedLabel != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  updatedLabel!,
                  style: typography.micro12.copyWith(color: colors.text2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The web sibling's 168×32 polyline: 4px vertical inset, accent-start
/// stroke 1.5, accent-end 2.5px end dot.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
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
      size.height - 4 - ((values[i] - min) / range) * (size.height - 8),
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
        Offset(size.width, point(values.length - 1).dy),
        2.5,
        Paint()..color = endDot,
      );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.stroke != stroke ||
      oldDelegate.endDot != endDot;
}
