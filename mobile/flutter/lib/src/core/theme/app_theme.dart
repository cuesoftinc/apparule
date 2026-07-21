import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Light + dark [ThemeData] built from the same token set
/// (mobile-implementation.md §7; design.md §2's true-black dark palette).
/// Components read tokens through the [ThemeExtension]s — never raw hexes.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    const typography = AppTypography.standard;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accentStart,
      onPrimary: colors.onAccent,
      secondary: colors.accentEnd,
      onSecondary: colors.onAccent,
      error: colors.error,
      onError: colors.onAccent,
      surface: colors.bg,
      onSurface: colors.text,
      surfaceContainerLow: colors.bgElev,
      surfaceContainerHighest: colors.bgElev,
      onSurfaceVariant: colors.text2,
      outline: colors.border,
      outlineVariant: colors.border,
    );
    final textTheme = TextTheme(
      displaySmall: typography.display32Bold,
      headlineSmall: typography.title24Bold,
      titleLarge: typography.title20SemiBold,
      titleMedium: typography.body16SemiBold,
      bodyLarge: typography.body16,
      bodyMedium: typography.body14,
      bodySmall: typography.caption13,
      labelLarge: typography.body16SemiBold,
      labelMedium: typography.body14,
      labelSmall: typography.micro12,
    ).apply(bodyColor: colors.text, displayColor: colors.text);

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: typography.title20SemiBold.copyWith(
          color: colors.text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        // Outline default / filled active carries the selection state
        // (IG convention, design.md §2); the C-series tab-bar module in the
        // design wave binds the exact per-state token spec.
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.text
                : colors.text2,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => typography.micro12.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.text
                : colors.text2,
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        colors,
        AppSpacing.standard,
        AppRadii.standard,
        typography,
        AppMotion.standard,
      ],
    );
  }
}
