import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/features/measurements/data/capture_guide_flag.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_view_model.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one capture entry gesture (mobile-implementation.md §10): guide on
/// first run, straight to the viewfinder once the persisted flag is set.
/// Shared by the ➕ chooser's "Take measurements" card (M-11), the C1b
/// interstitial, and the vault's capture option cards.
///
/// A-10b: a scan maps the customer's FULL tailor template, so capture is
/// template-gated exactly like manual entry — a null template interposes
/// the one-time chooser sheet before the flow opens.
Future<void> launchCaptureFlow(BuildContext context, WidgetRef ref) async {
  final template = await ref.read(manualTemplateProvider.future);
  if (!context.mounted) return;
  if (template == null) {
    final picked = await _chooseTemplate(context, ref);
    if (picked != true || !context.mounted) return;
  }
  final guideSeen = await ref.read(captureGuideFlagProvider.future);
  if (!context.mounted) return;
  if (guideSeen) {
    await const CaptureRoute().push<void>(context);
  } else {
    await const CaptureGuideRoute().push<void>(context);
  }
}

/// The A-10 one-time chooser as a modal sheet — the pick persists to the
/// profile (editable later in Settings) and refreshes [manualTemplate].
Future<bool?> _chooseTemplate(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final theme = Theme.of(sheetContext);
      final colors = theme.extension<AppColors>()!;
      final typography = theme.extension<AppTypography>()!;
      Future<void> pick(MeasurementTemplate template) async {
        await ref
            .read(profileRepositoryProvider)
            .setMeasurementTemplate(
              template,
            );
        ref.invalidate(manualTemplateProvider);
        if (sheetContext.mounted) Navigator.of(sheetContext).pop(true);
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.manualTemplateBody,
                style: typography.caption13.copyWith(color: colors.text2),
              ),
              const SizedBox(height: 16),
              Button(
                label: l10n.manualTemplateWomen,
                kind: ButtonKind.quiet,
                expand: true,
                onPressed: () => pick(MeasurementTemplate.women),
              ),
              const SizedBox(height: 12),
              Button(
                label: l10n.manualTemplateMen,
                kind: ButtonKind.quiet,
                expand: true,
                onPressed: () => pick(MeasurementTemplate.men),
              ),
            ],
          ),
        ),
      );
    },
  );
}
