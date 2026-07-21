import 'package:apparule/src/core/theme/app_theme.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('tokens resolve through the theme extensions', () {
      final theme = AppTheme.light();

      final colors = theme.extension<AppColors>()!;
      expect(colors.bg, const Color(0xFFFFFFFF));
      expect(colors.accentStart, const Color(0xFFE1306C));
      expect(colors.accentEnd, const Color(0xFFF77737));
      expect(colors.accentText, const Color(0xFFDB2967));

      final spacing = theme.extension<AppSpacing>()!;
      expect(spacing.s1, 4);
      expect(spacing.s2, 8);
      expect(spacing.s16, 64);

      final radii = theme.extension<AppRadii>()!;
      expect(radii.card, 8);
      expect(radii.pill, 9999);

      final typography = theme.extension<AppTypography>()!;
      expect(typography.body14.fontSize, 14);
      expect(typography.display32Bold.letterSpacing, -0.5);
      expect(typography.title24Bold.letterSpacing, -0.25);
      expect(typography.title20SemiBold.fontWeight, FontWeight.w600);
      expect(typography.body14.fontFamily, 'Inter');

      final motion = theme.extension<AppMotion>()!;
      expect(motion.fast, const Duration(milliseconds: 120));
      expect(motion.base, const Duration(milliseconds: 200));
    });

    test('light and dark build from the same set and differ per mode', () {
      final light = AppTheme.light().extension<AppColors>()!;
      final dark = AppTheme.dark().extension<AppColors>()!;

      // True-black dark palette (design.md §2).
      expect(light.bg, const Color(0xFFFFFFFF));
      expect(dark.bg, const Color(0xFF000000));
      expect(dark.bgElev, const Color(0xFF121212));
      expect(light.bg == dark.bg, isFalse);
      expect(light.text == dark.text, isFalse);

      // Mode-invariant tokens stay shared.
      expect(light.accentStart, dark.accentStart);
      expect(light.accentEnd, dark.accentEnd);
      expect(light.like, dark.like);
      expect(light.onAccent, dark.onAccent);
    });

    test('scaffold and scheme bind the bg/text tokens', () {
      final light = AppTheme.light();
      final colors = light.extension<AppColors>()!;
      expect(light.scaffoldBackgroundColor, colors.bg);
      expect(light.colorScheme.onSurface, colors.text);
      expect(light.colorScheme.outline, colors.border);
    });
  });
}
