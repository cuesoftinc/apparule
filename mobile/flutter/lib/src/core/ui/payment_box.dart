import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `PaymentBox` set's `state` axis (90:1103).
enum PaymentBoxState {
  quoted,
  paying,
  escrowHeld,
  released,
  refunded,
  disputeFrozen,
}

/// The `role` axis — whose side of the escrow the box narrates.
enum PaymentRole { customer, designer }

/// PaymentBox — the Figma `PaymentBox` set (90:1103); web sibling
/// `PaymentBox.tsx` (MI-15). Axes: `state` quoted (pay CTA) / paying
/// (spinner) / escrow-held (shield + first-payment explainer) / released /
/// refunded / dispute-frozen · `role` customer/designer. Carries the
/// itemized 10% fee line (A-1, ratified); money text sets
/// `FontFeature.tabularFigures()` (tnum canon — the Figma escrow masters
/// still miss the manual toggle; Flutter renders it regardless).
class PaymentBox extends StatelessWidget {
  const PaymentBox({
    required this.state,
    required this.role,
    required this.quoteCents,
    this.currency = 'NGN',
    this.showEscrowExplainer = false,
    this.onPay,
    this.onAction,
    super.key,
  });

  final PaymentBoxState state;
  final PaymentRole role;

  /// Quote amount in kobo/cents.
  final int quoteCents;

  final String currency;

  /// MI-15: the escrow explainer expands beneath on first payment.
  final bool showEscrowExplainer;

  /// The `quoted` (customer) pay CTA.
  final VoidCallback? onPay;

  /// Secondary CTAs (Edit quote / View payout / dispute actions),
  /// called with the tapped label.
  final ValueChanged<String>? onAction;

  /// 10% platform fee (A-1, ratified).
  static const double feeRate = 0.1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final fee = (quoteCents * feeRate).round();
    final net = quoteCents - fee;
    final shape = _shapeFor(
      price: formatNaira(quoteCents, currency: currency),
      fee: formatNaira(fee, currency: currency),
      net: formatNaira(net, currency: currency),
    );
    final iconColor = switch (shape.iconTone) {
      _IconTone.success => colors.success,
      _IconTone.warn => colors.warn,
      _IconTone.error => colors.error,
      null => null,
    };

    const tnum = <FontFeature>[FontFeature.tabularFigures()];

    return Semantics(
      label: 'Payment',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElev,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (shape.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(shape.icon, size: 18, color: iconColor),
                  ),
                Expanded(
                  child: Text(
                    shape.headline,
                    style: typography.body16SemiBold.copyWith(
                      color: colors.text,
                      fontFeatures: tnum,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              shape.body,
              style: typography.caption13.copyWith(
                color: colors.text2,
                fontFeatures: tnum,
              ),
            ),
            if (shape.cta != null) ...<Widget>[
              const SizedBox(height: 8),
              Button(
                label: shape.cta!.label,
                kind: shape.cta!.kind,
                loading: shape.cta!.loading,
                expand: true,
                onPressed: shape.cta!.kind == ButtonKind.gradientPrimary
                    ? onPay
                    : () => onAction?.call(shape.cta!.label),
              ),
            ],
            if (showEscrowExplainer) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(radii.card),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 8),
                      child: Icon(
                        LucideIcons.info,
                        size: 16,
                        color: colors.text2,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Your money stays with Apparule — not the designer '
                        '— until you confirm delivery. If anything goes '
                        'wrong, you can open a dispute and get refunded.',
                        style: typography.caption13.copyWith(
                          color: colors.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Copy and anatomy per state × role — the Figma masters' shapes,
  /// carried verbatim from the web sibling.
  _PaymentShape _shapeFor({
    required String price,
    required String fee,
    required String net,
  }) {
    final customer = role == PaymentRole.customer;
    switch (state) {
      case PaymentBoxState.quoted:
        return customer
            ? _PaymentShape(
                headline: 'Quote · $price',
                body: 'Includes 10% platform fee · $fee',
                cta: _PaymentCta('Pay $price', ButtonKind.gradientPrimary),
              )
            : _PaymentShape(
                headline: 'Quote sent · $price',
                body: 'You receive $net after the 10% platform fee',
                cta: const _PaymentCta('Edit quote', ButtonKind.quiet),
              );
      case PaymentBoxState.paying:
        return customer
            ? _PaymentShape(
                headline: 'Quote · $price',
                body: 'Confirming payment with your bank…',
                cta: const _PaymentCta(
                  'Paying',
                  ButtonKind.gradientPrimary,
                  loading: true,
                ),
              )
            : const _PaymentShape(
                headline: 'Payment in progress',
                body: 'The customer is completing payment',
              );
      case PaymentBoxState.escrowHeld:
        return _PaymentShape(
          icon: LucideIcons.shieldCheck,
          iconTone: _IconTone.success,
          headline: '$price held in escrow',
          body: customer
              ? 'Funds release to the designer when you confirm delivery'
              : '$net releases to you on delivery confirmation',
        );
      case PaymentBoxState.released:
        return customer
            ? const _PaymentShape(
                icon: LucideIcons.check,
                iconTone: _IconTone.success,
                headline: 'Payment released',
                body: 'You confirmed delivery — order complete',
              )
            : _PaymentShape(
                icon: LucideIcons.check,
                iconTone: _IconTone.success,
                headline: '$net released to you',
                body: 'Payout arrives within 2 business days',
                cta: const _PaymentCta('View payout', ButtonKind.quiet),
              );
      case PaymentBoxState.refunded:
        return customer
            ? _PaymentShape(
                icon: LucideIcons.clock,
                iconTone: _IconTone.warn,
                headline: '$price refunded',
                body: 'Refund to your original payment method in 5–7 days',
              )
            : const _PaymentShape(
                icon: LucideIcons.clock,
                iconTone: _IconTone.warn,
                headline: 'Order refunded',
                body: 'Escrow returned to the customer',
              );
      case PaymentBoxState.disputeFrozen:
        return _PaymentShape(
          icon: LucideIcons.triangleAlert,
          iconTone: _IconTone.error,
          headline: 'Funds frozen',
          body: 'Escrow is on hold while the dispute is reviewed',
          cta: _PaymentCta(
            customer ? 'View dispute' : 'Respond to dispute',
            ButtonKind.quiet,
          ),
        );
    }
  }
}

enum _IconTone { success, warn, error }

class _PaymentShape {
  const _PaymentShape({
    required this.headline,
    required this.body,
    this.icon,
    this.iconTone,
    this.cta,
  });

  final IconData? icon;
  final _IconTone? iconTone;
  final String headline;
  final String body;
  final _PaymentCta? cta;
}

class _PaymentCta {
  const _PaymentCta(this.label, this.kind, {this.loading = false});

  final String label;
  final ButtonKind kind;
  final bool loading;
}
