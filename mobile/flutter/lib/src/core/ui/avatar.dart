import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `Avatar` set's `size` axis (42:189): 32/44/56/96. `s64` is
/// the StoryRailItem frame geometry ([Decided 2026-07-19]: 64px ring
/// wrapping a 56px photo) — mastered inside that set, carried here so both
/// modules share one ring implementation (web sibling parity).
enum AvatarSize {
  s32(32),
  s44(44),
  s56(56),
  s64(64),
  s96(96);

  const AvatarSize(this.dimension);

  /// Outer frame size in px.
  final double dimension;
}

/// The `ring` axis — MI-8 story ring and MI-11 vault-freshness ring share
/// this atom (gradient <30d · amber 30–90d · gray >90d/none).
enum AvatarRing { none, gradient, amber, gray }

/// The `badge` axis.
enum AvatarBadge { none, designerVerified }

/// Avatar — the Figma `Avatar` set (42:189); web sibling `Avatar.tsx`.
/// Ring geometry ([Decided 2026-07-19]): the photo is a circle inside a
/// SEPARATE ring stroke (2px; 3px at 96) with a consistent 2px clear gap —
/// 32 → 24 photo · 56 → 48 · 64 → 56 · 96 → 86. Initials render when no
/// image is provided. Freshness rings appear on the C9 own header + C7
/// only; other profiles stay plain.
class Avatar extends StatelessWidget {
  const Avatar({
    required this.name,
    this.size = AvatarSize.s44,
    this.ring = AvatarRing.none,
    this.badge = AvatarBadge.none,
    this.image,
    super.key,
  });

  /// Display or user name — drives the semantics label + initials fallback.
  final String name;

  final AvatarSize size;
  final AvatarRing ring;
  final AvatarBadge badge;

  /// Avatar photo; `null` renders the initials fallback.
  final ImageProvider<Object>? image;

  /// MI-11 freshness → ring mapping (design.md §2) — one mapping for every
  /// own-avatar surface. `null` freshness (no measurements) reads gray.
  static AvatarRing freshnessRing(String? freshness) {
    return switch (freshness) {
      'fresh' => AvatarRing.gradient,
      'aging' => AvatarRing.amber,
      _ => AvatarRing.gray,
    };
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'[\s._-]+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    final dimension = size.dimension;
    final stroke = dimension >= 96 ? 3.0 : 2.0;
    final ringed = ring != AvatarRing.none;
    final photoDimension = ringed ? dimension - 2 * stroke - 4 : dimension;

    // Figma master: solid border-token fill, text-2 initials
    // (12px at 32 → 28px at 96).
    final initialsStyle = switch (size) {
      AvatarSize.s96 => typography.title24Bold.copyWith(fontSize: 28),
      AvatarSize.s64 || AvatarSize.s56 => typography.body16SemiBold,
      AvatarSize.s44 => typography.body14.copyWith(
        fontWeight: FontWeight.w600,
      ),
      AvatarSize.s32 => typography.micro12.copyWith(
        fontWeight: FontWeight.w600,
      ),
    };

    Widget photo = Container(
      width: photoDimension,
      height: photoDimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.border,
        shape: BoxShape.circle,
        image: image == null
            ? null
            : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      child: image == null
          ? Text(
              _initials(name),
              style: initialsStyle.copyWith(color: colors.text2),
            )
          : null,
    );

    if (ringed) {
      photo = Container(
        width: dimension,
        height: dimension,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: ring == AvatarRing.gradient ? colors.accentGradient : null,
          color: switch (ring) {
            AvatarRing.amber => colors.warn,
            AvatarRing.gray => colors.border,
            _ => null,
          },
        ),
        // The 2px clear gap between ring stroke and photo.
        child: Container(
          width: dimension - 2 * stroke,
          height: dimension - 2 * stroke,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.bg, shape: BoxShape.circle),
          child: photo,
        ),
      );
    }

    if (badge == AvatarBadge.designerVerified) {
      // Figma master: accent-gradient disc, 2px bg keyline, white check,
      // flush to the bottom-right corner (14px at 32/44 → 28px at 96).
      final disc = dimension >= 96
          ? 28.0
          : dimension >= 56
          ? 20.0
          : 14.0;
      final glyph = dimension >= 96
          ? 17.0
          : dimension >= 56
          ? 12.0
          : 8.0;
      photo = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          photo,
          Positioned(
            right: 0,
            bottom: 0,
            child: Semantics(
              label: 'Verified designer',
              child: Container(
                width: disc,
                height: disc,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: colors.accentGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.bg, width: 2),
                ),
                child: Icon(
                  LucideIcons.check,
                  size: glyph,
                  color: colors.onAccent,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: name,
      image: image != null,
      child: SizedBox(width: dimension, height: dimension, child: photo),
    );
  }
}
