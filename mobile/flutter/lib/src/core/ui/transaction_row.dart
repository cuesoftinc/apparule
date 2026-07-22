import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `TransactionRow` kind axis (§8.2b earnings rows): payout /
/// escrow-held / fee-line (10%). Canonical glyph + label ride the enum
/// (web sibling `KIND_META` parity — card for payouts, shield for
/// escrow, info for the fee line).
enum TransactionKind {
  payout(LucideIcons.creditCard, 'Payout'),
  escrowHeld(LucideIcons.shieldCheck, 'Escrow held'),
  feeLine(LucideIcons.info, 'Platform fee (10%)');

  const TransactionKind(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// TransactionRow — the Figma `EarningsSummary + TransactionRow` set
/// (97:1281 masters); web sibling `TransactionRow` in
/// `EarningsSummary.tsx`. Leading kind glyph in a pill ring, label line
/// (default `{kind} · {orderNumber}`, overridable — the canvas payout
/// rows carry free text: "Payout to GTBank ••• 4521"), meta line
/// (`provider ref · date`), and the tabular amount: credits read `+` in
/// success, debits in the text token (design.md §8.2b). Consumed by C14.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    required this.kind,
    required this.amountCents,
    this.currency = 'NGN',
    this.label,
    this.orderNumber,
    this.providerRef,
    this.dateLabel,
    super.key,
  });

  final TransactionKind kind;

  /// Signed amount in kobo/cents — negative rows are debits.
  final int amountCents;

  final String currency;

  /// First-line override (canvas free-text rows); defaults to
  /// `{kind label} · {orderNumber}`.
  final String? label;

  /// The `#APR-1042` idiom — feeds the default label.
  final String? orderNumber;

  /// Paystack reference (`PSK-…`) — leads the meta line when present.
  final String? providerRef;

  /// Pre-formatted date for the meta line (`Jul 16` — consumers pin the
  /// narrative clock; the module never reads `DateTime.now()`).
  final String? dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final negative = amountCents < 0;
    final line =
        label ??
        (orderNumber == null ? kind.label : '${kind.label} · $orderNumber');
    final meta = <String>[?providerRef, ?dateLabel].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(radii.pill),
            ),
            child: Icon(kind.icon, size: 16, color: colors.text2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.micro12.copyWith(color: colors.text2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${negative ? '' : '+'}'
            '${formatNaira(amountCents, currency: currency)}',
            style: typography.body14.copyWith(
              fontWeight: FontWeight.w600,
              color: negative ? colors.text : colors.success,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
