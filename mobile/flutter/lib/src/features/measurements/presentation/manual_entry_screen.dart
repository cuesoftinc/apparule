import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/manual_measure_row.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// MI-13 manual entry — the C6 fallback (pages.md C6; flows/vault.md §2):
/// tape-measured values over the ManualMeasureRow kit, advisory
/// double-check hints (never a hard block), saved as a `method: manual`
/// session the vault lists like any scan.
class ManualEntryScreen extends ConsumerWidget {
  const ManualEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final state = ref.watch(manualEntryViewModelProvider);
    final viewModel = ref.read(manualEntryViewModelProvider.notifier);

    ref.listen(manualEntryViewModelProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        const VaultRoute().go(context);
      }
    });

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.manualEntryTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const HomeRoute().go(context);
          }
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              l10n.manualEntryBody,
              style: typography.caption13.copyWith(color: colors.text2),
            ),
            const SizedBox(height: 16),
            for (final spec in kManualMeasures) ...<Widget>[
              ManualMeasureRow(
                name: spec.name,
                valueCm: state.valuesCm[spec.name],
                min: spec.min,
                max: spec.max,
                unit: state.unit,
                onChanged: (value) => viewModel.setValue(spec.name, value),
                onUnitChanged: viewModel.setUnit,
                error: _advisory(l10n, state.valuesCm[spec.name], spec),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            Button(
              label: l10n.manualEntrySave,
              expand: true,
              loading: state.saving,
              onPressed: state.valuesCm.isEmpty ? null : viewModel.save,
            ),
          ],
        ),
      ),
    );
  }

  /// The flows/vault.md §2 advisory: out-of-range asks for a double-check
  /// — bodies vary, so it never blocks the save.
  String? _advisory(
    AppLocalizations l10n,
    double? valueCm,
    ManualMeasureSpec spec,
  ) {
    if (valueCm == null || (valueCm >= spec.min && valueCm <= spec.max)) {
      return null;
    }
    return l10n.manualEntryDoubleCheck(spec.min.round(), spec.max.round());
  }
}
