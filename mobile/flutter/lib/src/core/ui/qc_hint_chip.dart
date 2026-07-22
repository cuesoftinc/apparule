import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `QCHintChip` set's `code` axis (62:634) — 1:1 with the
/// capture-qc.md §1–2 fail codes. Each value carries its canonical
/// guidance copy (flows/vault.md QC-failures row, verbatim — the same
/// strings the 422 envelope carries) and the glyph naming the failure
/// family.
enum QcFailCode {
  noBody('no_body', 'Make sure your whole body is visible', LucideIcons.user),
  multipleBodies(
    'multiple_bodies',
    "Make sure you're alone in frame",
    LucideIcons.user,
  ),
  partialBody('partial_body', 'Include head to ankles', LucideIcons.ruler),
  undecodableImage(
    'undecodable_image',
    "That image couldn't be read — try another photo",
    LucideIcons.x,
  ),
  lowResolution(
    'low_resolution',
    'Move closer or use a higher-quality camera',
    LucideIcons.camera,
  ),
  poorLighting(
    'poor_lighting',
    'Find better lighting — avoid strong backlight',
    LucideIcons.camera,
  ),
  blurry('blurry', 'Hold steady and retake', LucideIcons.camera),
  notFrontal(
    'not_frontal',
    'Face the camera straight on',
    LucideIcons.user,
  ),
  cameraTilt('camera_tilt', 'Hold the phone upright', LucideIcons.camera),
  armsPosition(
    'arms_position',
    'Keep arms slightly away from your body',
    LucideIcons.user,
  ),
  tooFar(
    'too_far',
    'Move closer — fill more of the frame',
    LucideIcons.search,
  );

  const QcFailCode(this.wireName, this.guidance, this.icon);

  /// The capture-qc.md wire code (`POST /measure` 422 envelope).
  final String wireName;

  /// One actionable retake instruction — surfaced first-failure-only,
  /// never a stacked list (capture-qc.md reporting rule).
  final String guidance;

  final IconData icon;

  /// Maps a wire code (`not_frontal`) to its enum value; `null` when the
  /// code is unknown (forward-compatible with additive QC codes).
  static QcFailCode? fromWireName(String name) {
    for (final code in values) {
      if (code.wireName == name) return code;
    }
    return null;
  }
}

/// QCHintChip — the Figma `QCHintChip` set (62:634); web sibling
/// `QCHintChip.tsx`. Inverse surface (text-token fill, bg-token content —
/// the Toast technique), 13px semibold, pill radius. Consumed by the C6
/// QC states through the CaptureOverlay's qc-hint slot.
class QCHintChip extends StatelessWidget {
  const QCHintChip({required this.code, super.key});

  final QcFailCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.text,
          borderRadius: BorderRadius.circular(radii.pill),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(code.icon, size: 16, color: colors.bg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                code.guidance,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.caption13.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.bg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
