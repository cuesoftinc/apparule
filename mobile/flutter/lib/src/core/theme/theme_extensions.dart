// One ThemeExtension per token group (mobile-implementation.md §7):
// color / spacing / radius / type, plus motion for the shared MI
// duration/easing tokens. Values come exclusively from the generated
// token classes under tokens/ (never raw hexes — web-implementation.md §1
// discipline applied to Flutter theming) and, for type/easing, from the
// written contract in design.md §2.
import 'dart:ui' show lerpDouble;

import 'package:apparule/src/core/theme/tokens/color_tokens.dart';
import 'package:apparule/src/core/theme/tokens/motion_tokens.dart';
import 'package:apparule/src/core/theme/tokens/radius_tokens.dart';
import 'package:apparule/src/core/theme/tokens/spacing_tokens.dart';
import 'package:flutter/material.dart';

/// Color tokens (design.md §2) — one field per Figma variable.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.bgElev,
    required this.border,
    required this.text,
    required this.text2,
    required this.accentStart,
    required this.accentEnd,
    required this.onAccent,
    required this.link,
    required this.like,
    required this.success,
    required this.warn,
    required this.error,
    required this.accentText,
    required this.successText,
    required this.warnText,
    required this.text2Text,
  });

  final Color bg;
  final Color bgElev;
  final Color border;
  final Color text;
  final Color text2;
  final Color accentStart;
  final Color accentEnd;
  final Color onAccent;
  final Color link;
  final Color like;
  final Color success;
  final Color warn;
  final Color error;
  final Color accentText;
  final Color successText;
  final Color warnText;
  final Color text2Text;

  static const AppColors light = AppColors(
    bg: AppColorTokensLight.bg,
    bgElev: AppColorTokensLight.bgElev,
    border: AppColorTokensLight.border,
    text: AppColorTokensLight.text,
    text2: AppColorTokensLight.text2,
    accentStart: AppColorTokensLight.accentStart,
    accentEnd: AppColorTokensLight.accentEnd,
    onAccent: AppColorTokensLight.onAccent,
    link: AppColorTokensLight.link,
    like: AppColorTokensLight.like,
    success: AppColorTokensLight.success,
    warn: AppColorTokensLight.warn,
    error: AppColorTokensLight.error,
    accentText: AppColorTokensLight.accentText,
    successText: AppColorTokensLight.successText,
    warnText: AppColorTokensLight.warnText,
    text2Text: AppColorTokensLight.text2Text,
  );

  static const AppColors dark = AppColors(
    bg: AppColorTokensDark.bg,
    bgElev: AppColorTokensDark.bgElev,
    border: AppColorTokensDark.border,
    text: AppColorTokensDark.text,
    text2: AppColorTokensDark.text2,
    accentStart: AppColorTokensDark.accentStart,
    accentEnd: AppColorTokensDark.accentEnd,
    onAccent: AppColorTokensDark.onAccent,
    link: AppColorTokensDark.link,
    like: AppColorTokensDark.like,
    success: AppColorTokensDark.success,
    warn: AppColorTokensDark.warn,
    error: AppColorTokensDark.error,
    accentText: AppColorTokensDark.accentText,
    successText: AppColorTokensDark.successText,
    warnText: AppColorTokensDark.warnText,
    text2Text: AppColorTokensDark.text2Text,
  );

  /// The Apparule gradient — `accent-start` → `accent-end` (two variables;
  /// Figma cannot bind a gradient stop to one, design.md §7).
  LinearGradient get accentGradient =>
      LinearGradient(colors: <Color>[accentStart, accentEnd]);

  @override
  AppColors copyWith({
    Color? bg,
    Color? bgElev,
    Color? border,
    Color? text,
    Color? text2,
    Color? accentStart,
    Color? accentEnd,
    Color? onAccent,
    Color? link,
    Color? like,
    Color? success,
    Color? warn,
    Color? error,
    Color? accentText,
    Color? successText,
    Color? warnText,
    Color? text2Text,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      bgElev: bgElev ?? this.bgElev,
      border: border ?? this.border,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      accentStart: accentStart ?? this.accentStart,
      accentEnd: accentEnd ?? this.accentEnd,
      onAccent: onAccent ?? this.onAccent,
      link: link ?? this.link,
      like: like ?? this.like,
      success: success ?? this.success,
      warn: warn ?? this.warn,
      error: error ?? this.error,
      accentText: accentText ?? this.accentText,
      successText: successText ?? this.successText,
      warnText: warnText ?? this.warnText,
      text2Text: text2Text ?? this.text2Text,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgElev: Color.lerp(bgElev, other.bgElev, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      accentStart: Color.lerp(accentStart, other.accentStart, t)!,
      accentEnd: Color.lerp(accentEnd, other.accentEnd, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      link: Color.lerp(link, other.link, t)!,
      like: Color.lerp(like, other.like, t)!,
      success: Color.lerp(success, other.success, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      error: Color.lerp(error, other.error, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warnText: Color.lerp(warnText, other.warnText, t)!,
      text2Text: Color.lerp(text2Text, other.text2Text, t)!,
    );
  }
}

/// Spacing tokens — the 4px base grid (design.md §2).
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.s6,
    required this.s8,
    required this.s12,
    required this.s16,
  });

  final double s1;
  final double s2;
  final double s3;
  final double s4;
  final double s6;
  final double s8;
  final double s12;
  final double s16;

  static const AppSpacing standard = AppSpacing(
    s1: AppSpaceTokens.s1,
    s2: AppSpaceTokens.s2,
    s3: AppSpaceTokens.s3,
    s4: AppSpaceTokens.s4,
    s6: AppSpaceTokens.s6,
    s8: AppSpaceTokens.s8,
    s12: AppSpaceTokens.s12,
    s16: AppSpaceTokens.s16,
  );

  @override
  AppSpacing copyWith({
    double? s1,
    double? s2,
    double? s3,
    double? s4,
    double? s6,
    double? s8,
    double? s12,
    double? s16,
  }) {
    return AppSpacing(
      s1: s1 ?? this.s1,
      s2: s2 ?? this.s2,
      s3: s3 ?? this.s3,
      s4: s4 ?? this.s4,
      s6: s6 ?? this.s6,
      s8: s8 ?? this.s8,
      s12: s12 ?? this.s12,
      s16: s16 ?? this.s16,
    );
  }

  @override
  AppSpacing lerp(AppSpacing? other, double t) {
    if (other == null) return this;
    return AppSpacing(
      s1: lerpDouble(s1, other.s1, t)!,
      s2: lerpDouble(s2, other.s2, t)!,
      s3: lerpDouble(s3, other.s3, t)!,
      s4: lerpDouble(s4, other.s4, t)!,
      s6: lerpDouble(s6, other.s6, t)!,
      s8: lerpDouble(s8, other.s8, t)!,
      s12: lerpDouble(s12, other.s12, t)!,
      s16: lerpDouble(s16, other.s16, t)!,
    );
  }
}

/// Radius tokens — 8px cards/sheets, full-round pills (design.md §2).
@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({required this.card, required this.pill});

  final double card;
  final double pill;

  static const AppRadii standard = AppRadii(
    card: AppRadiusTokens.card,
    pill: AppRadiusTokens.pill,
  );

  BorderRadius get cardRadius => BorderRadius.circular(card);
  BorderRadius get pillRadius => BorderRadius.circular(pill);

  @override
  AppRadii copyWith({double? card, double? pill}) {
    return AppRadii(card: card ?? this.card, pill: pill ?? this.pill);
  }

  @override
  AppRadii lerp(AppRadii? other, double t) {
    if (other == null) return this;
    return AppRadii(
      card: lerpDouble(card, other.card, t)!,
      pill: lerpDouble(pill, other.pill, t)!,
    );
  }
}

/// Type tokens — the design.md §2 scale (12/13/14/16/20/24/32, weights
/// 400/600/700, tracking −0.25 at 24 / −0.5 at 32), named after the Figma
/// local type styles (design.md §7). Colors are applied by the theme, not
/// baked in here.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.display32Bold,
    required this.title24Bold,
    required this.title20SemiBold,
    required this.body16SemiBold,
    required this.body16,
    required this.body14,
    required this.caption13,
    required this.micro12,
  });

  final TextStyle display32Bold;
  final TextStyle title24Bold;
  final TextStyle title20SemiBold;
  final TextStyle body16SemiBold;
  final TextStyle body16;
  final TextStyle body14;
  final TextStyle caption13;
  final TextStyle micro12;

  static const String fontFamily = 'Inter';

  static const AppTypography standard = AppTypography(
    display32Bold: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    title24Bold: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
    ),
    title20SemiBold: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    body16SemiBold: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    body16: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    body14: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    caption13: TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w400,
    ),
    micro12: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
  );

  @override
  AppTypography copyWith({
    TextStyle? display32Bold,
    TextStyle? title24Bold,
    TextStyle? title20SemiBold,
    TextStyle? body16SemiBold,
    TextStyle? body16,
    TextStyle? body14,
    TextStyle? caption13,
    TextStyle? micro12,
  }) {
    return AppTypography(
      display32Bold: display32Bold ?? this.display32Bold,
      title24Bold: title24Bold ?? this.title24Bold,
      title20SemiBold: title20SemiBold ?? this.title20SemiBold,
      body16SemiBold: body16SemiBold ?? this.body16SemiBold,
      body16: body16 ?? this.body16,
      body14: body14 ?? this.body14,
      caption13: caption13 ?? this.caption13,
      micro12: micro12 ?? this.micro12,
    );
  }

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) return this;
    return AppTypography(
      display32Bold: TextStyle.lerp(display32Bold, other.display32Bold, t)!,
      title24Bold: TextStyle.lerp(title24Bold, other.title24Bold, t)!,
      title20SemiBold: TextStyle.lerp(
        title20SemiBold,
        other.title20SemiBold,
        t,
      )!,
      body16SemiBold: TextStyle.lerp(body16SemiBold, other.body16SemiBold, t)!,
      body16: TextStyle.lerp(body16, other.body16, t)!,
      body14: TextStyle.lerp(body14, other.body14, t)!,
      caption13: TextStyle.lerp(caption13, other.caption13, t)!,
      micro12: TextStyle.lerp(micro12, other.micro12, t)!,
    );
  }
}

/// Motion tokens — shared durations from the Figma collection plus the
/// design.md §2 easing curves (curves are contract values, not Figma
/// variables — Figma has no easing-token type).
@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    required this.fast,
    required this.base,
    required this.entrance,
    required this.slow,
    required this.standardEasing,
    required this.exitEasing,
  });

  final Duration fast;
  final Duration base;
  final Duration entrance;
  final Duration slow;
  final Curve standardEasing;
  final Curve exitEasing;

  static const AppMotion standard = AppMotion(
    fast: AppDurationTokens.fast,
    base: AppDurationTokens.base,
    entrance: AppDurationTokens.entrance,
    slow: AppDurationTokens.slow,
    // cubic-bezier(0.2, 0, 0, 1) / cubic-bezier(0.4, 0, 1, 1) — design.md §2.
    standardEasing: Cubic(0.2, 0, 0, 1),
    exitEasing: Cubic(0.4, 0, 1, 1),
  );

  @override
  AppMotion copyWith({
    Duration? fast,
    Duration? base,
    Duration? entrance,
    Duration? slow,
    Curve? standardEasing,
    Curve? exitEasing,
  }) {
    return AppMotion(
      fast: fast ?? this.fast,
      base: base ?? this.base,
      entrance: entrance ?? this.entrance,
      slow: slow ?? this.slow,
      standardEasing: standardEasing ?? this.standardEasing,
      exitEasing: exitEasing ?? this.exitEasing,
    );
  }

  @override
  AppMotion lerp(AppMotion? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
