import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `CaptureOptionCard` set's `mode` axis (66:721) — canonical
/// copy rides the enum (the Figma masters carry it). `photo-upload` was
/// renamed from `webcam-upload` in the M-12 webcam purge (web capture is
/// upload-only; mobile keeps the live guided camera — "Use your camera"
/// is the mobile C7 string, web B4 instances override to upload
/// phrasing); the subtitle carries the two-photo canon (M-10).
enum CaptureOptionMode {
  photoUpload(
    LucideIcons.camera,
    'Use your camera',
    'Two photos — we measure automatically',
  ),
  manualEntry(
    LucideIcons.pencilRuler,
    'Enter manually',
    'Tape-measure your key metrics',
  );

  const CaptureOptionMode(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

/// CaptureOptionCard — the Figma `CaptureOptionCard` set (66:721); web
/// sibling `CaptureOptionCard.tsx` (B4 vault entry cards). The C7 vault
/// entry choice: camera capture vs manual entry. Soft accent-tint disc
/// (12% accent-start) with an accent glyph, title/body copy, trailing
/// chevron.
class CaptureOptionCard extends StatelessWidget {
  const CaptureOptionCard({required this.mode, this.onTap, super.key});

  final CaptureOptionMode mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElev,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(radii.card),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accentStart.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(radii.pill),
                ),
                child: Icon(mode.icon, size: 20, color: colors.accentStart),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      mode.title,
                      style: typography.body14.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.body,
                      style: typography.caption13.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 16, color: colors.text2),
            ],
          ),
        ),
      ),
    );
  }
}
