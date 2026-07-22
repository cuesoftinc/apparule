import 'dart:math' as math;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `EmptyState` set's `kind` axis (54:459) — every list defines
/// one. Canonical copy and CTA kinds ride the enum (web sibling parity);
/// primary CTAs paint the gradient, recovery/secondary ones stay quiet.
enum EmptyStateKind {
  feed(
    LucideIcons.house,
    'Follow designers to fill your feed',
    'Explore outfits',
    ButtonKind.gradientPrimary,
  ),
  vault(
    LucideIcons.ruler,
    'No measurements yet — take your first scan',
    'Take measurement',
    ButtonKind.gradientPrimary,
  ),
  orders(
    LucideIcons.package,
    'No orders yet',
    'Discover designers',
    ButtonKind.quiet,
  ),
  explore(
    LucideIcons.search,
    'Nothing matches that search',
    'Clear search',
    ButtonKind.quiet,
  ),
  notifications(
    LucideIcons.bell,
    "You're all caught up",
    'Back to feed',
    ButtonKind.quiet,
  ),
  cameraPermission(
    LucideIcons.camera,
    'Camera access is off — enable it in Settings to measure automatically',
    'Open Settings',
    ButtonKind.gradientPrimary,
    secondaryCta: 'Enter manually instead',
  );

  const EmptyStateKind(
    this.icon,
    this.line,
    this.cta,
    this.ctaKind, {
    this.secondaryCta,
  });

  final IconData icon;
  final String line;
  final String cta;
  final ButtonKind ctaKind;

  /// camera-permission carries a quiet secondary CTA (Figma 98:1274).
  final String? secondaryCta;
}

/// EmptyState — the Figma `EmptyState` set (54:459); web sibling
/// `EmptyState.tsx`. Pattern-bg illustration (a 4–6% geometric line
/// stand-in until the Afrocentric pattern asset ships, design.md §2) +
/// 88px dashed ring + one-liner + one CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.kind,
    this.line,
    this.ctaLabel,
    this.onCta,
    this.onSecondaryCta,
    super.key,
  });

  final EmptyStateKind kind;

  /// Copy overrides for screens that spec their own line/CTA.
  final String? line;
  final String? ctaLabel;

  final VoidCallback? onCta;
  final VoidCallback? onSecondaryCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radii.card),
      child: Stack(
        children: <Widget>[
          // Pattern background — 4–6% opacity geometric lines.
          Positioned.fill(
            child: CustomPaint(
              painter: _LinePatternPainter(
                color: colors.text.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Figma master: 88px dashed ring, 32px text-2 glyph.
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CustomPaint(
                    painter: _DashedCirclePainter(color: colors.border),
                    child: Center(
                      child: Icon(kind.icon, size: 32, color: colors.text2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    line ?? kind.line,
                    textAlign: TextAlign.center,
                    style: typography.caption13.copyWith(color: colors.text2),
                  ),
                ),
                const SizedBox(height: 16),
                Button(
                  label: ctaLabel ?? kind.cta,
                  kind: kind.ctaKind,
                  size: ButtonSize.sm,
                  onPressed: onCta ?? () {},
                ),
                if (kind.secondaryCta != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Button(
                    label: kind.secondaryCta!,
                    kind: ButtonKind.quiet,
                    size: ButtonSize.sm,
                    onPressed: onSecondaryCta ?? () {},
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The stand-in geometric pattern — 24px diagonal line grid (web sibling's
/// SVG `<pattern>`).
class _LinePatternPainter extends CustomPainter {
  const _LinePatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 24.0;
    final diagonal = size.width + size.height;
    for (var d = -size.height; d < diagonal; d += step) {
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LinePatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - 1) / 2;
    const dash = 4.0;
    const gap = 4.0;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dash + gap)).floor();
    final dashAngle = dash / radius;
    final stepAngle = 2 * math.pi / count;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * stepAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
