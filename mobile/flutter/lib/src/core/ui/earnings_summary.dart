import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';

/// EarningsSummary — the Figma `EarningsSummary` set (97:1249, single
/// component); web sibling `EarningsSummary.tsx`. Two cards: Available
/// (released balance) / In escrow (held). The 24px stats keep the BASE
/// success/warn hues (AA-large canon — `-text` variants are for small
/// text on tints) and set `FontFeature.tabularFigures()` (tnum ✔ in the
/// Figma master). Consumed by C14.
class EarningsSummary extends StatelessWidget {
  const EarningsSummary({
    required this.balanceCents,
    required this.pendingCents,
    this.currency = 'NGN',
    super.key,
  });

  /// Released balance in kobo/cents.
  final int balanceCents;

  /// Escrow-held amount in kobo/cents.
  final int pendingCents;

  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _BalanceCard(
            label: 'Available',
            amountCents: balanceCents,
            currency: currency,
            tone: _StatTone.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _BalanceCard(
            label: 'In escrow',
            amountCents: pendingCents,
            currency: currency,
            tone: _StatTone.warn,
          ),
        ),
      ],
    );
  }
}

enum _StatTone { success, warn }

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.amountCents,
    required this.currency,
    required this.tone,
  });

  final String label;
  final int amountCents;
  final String currency;
  final _StatTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElev,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: typography.caption13.copyWith(color: colors.text2),
          ),
          const SizedBox(height: 4),
          Text(
            formatNaira(amountCents, currency: currency),
            style: typography.title24Bold.copyWith(
              color: tone == _StatTone.success ? colors.success : colors.warn,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
