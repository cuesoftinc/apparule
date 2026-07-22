import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:apparule/src/features/earnings/presentation/payout_account_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// C13 — Payout account (canvas 205:2/6544/6553; pages.md B8 banking
/// form): bank Select (sheet of option rows) + account number with the
/// scripted Paystack resolution states — resolving spinner → resolved
/// name confirm ("Account name matches your profile") → save, or the
/// failed state with Retry + the contact-support link. Paystack handles
/// verification; Apparule never stores a BVN (footer).
class PayoutAccountScreen extends ConsumerStatefulWidget {
  const PayoutAccountScreen({super.key});

  @override
  ConsumerState<PayoutAccountScreen> createState() =>
      _PayoutAccountScreenState();
}

class _PayoutAccountScreenState extends ConsumerState<PayoutAccountScreen> {
  final TextEditingController _accountNumber = TextEditingController();

  @override
  void dispose() {
    _accountNumber.dispose();
    super.dispose();
  }

  Future<void> _pickBank(List<BankOption> banks) async {
    final picked = await Sheet.show<BankOption>(
      context,
      title: context.l10n.payoutBankLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final bank in banks)
            _BankOptionRow(
              bank: bank,
              onTap: () => Navigator.of(context).pop(bank),
            ),
        ],
      ),
    );
    if (picked != null) {
      ref.read(payoutAccountViewModelProvider.notifier).setBank(picked);
    }
  }

  Future<void> _save() async {
    final saved = await ref
        .read(payoutAccountViewModelProvider.notifier)
        .save();
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.payoutSavedToast)),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        const EarningsRoute().go(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final state = ref.watch(payoutAccountViewModelProvider);

    OutlineInputBorder border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.card),
      borderSide: BorderSide(color: colors.border),
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: typography.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
      ),
    );

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.payoutTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const SettingsRoute().go(context);
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Text(
            l10n.payoutIntro,
            style: typography.body14.copyWith(color: colors.text2),
          ),
          label(l10n.payoutBankLabel),
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => _pickBank(state.banks),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.bgElev,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(radii.card),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        state.bank?.name ?? l10n.payoutBankHint,
                        style: typography.body14.copyWith(
                          color: state.bank == null
                              ? colors.text2
                              : colors.text,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: colors.text2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          label(l10n.payoutAccountNumberLabel),
          TextField(
            controller: _accountNumber,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: typography.body14.copyWith(
              color: colors.text,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
            decoration: InputDecoration(
              hintText: l10n.payoutAccountNumberHint,
              hintStyle: typography.body14.copyWith(color: colors.text2),
              isDense: true,
              filled: true,
              fillColor: colors.bgElev,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: border(),
              enabledBorder: border(),
            ),
            onChanged: (value) => ref
                .read(payoutAccountViewModelProvider.notifier)
                .setAccountNumber(value),
          ),
          const SizedBox(height: 20),
          switch (state.phase) {
            PayoutFormPhase.idle => const SizedBox.shrink(),
            PayoutFormPhase.resolving => Row(
              children: <Widget>[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.accentStart,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.payoutResolving,
                  style: typography.body14.copyWith(color: colors.text2),
                ),
              ],
            ),
            PayoutFormPhase.resolved => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(LucideIcons.check, size: 18, color: colors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            state.resolution?.accountName ?? '',
                            style: typography.body14.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                          Text(
                            l10n.payoutResolvedHelper,
                            style: typography.caption13.copyWith(
                              color: colors.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Button(
                  label: l10n.payoutSave,
                  loading: state.saving,
                  expand: true,
                  onPressed: _save,
                ),
              ],
            ),
            PayoutFormPhase.failed => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      LucideIcons.triangleAlert,
                      size: 18,
                      color: colors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.payoutFailedTitle,
                            style: typography.body14.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.error,
                            ),
                          ),
                          Text(
                            l10n.payoutFailedHelper,
                            style: typography.caption13.copyWith(
                              color: colors.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Button(
                  label: l10n.payoutRetry,
                  kind: ButtonKind.quiet,
                  expand: true,
                  onPressed: () => ref
                      .read(payoutAccountViewModelProvider.notifier)
                      .retry(),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Button(
                    label: l10n.payoutContactSupport,
                    kind: ButtonKind.link,
                    onPressed: () => launchUrl(
                      Uri.parse('https://cuesoft.io/support'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              ],
            ),
          },
          const SizedBox(height: 48),
          Text(
            l10n.payoutFooter,
            textAlign: TextAlign.center,
            style: typography.caption13.copyWith(color: colors.text2),
          ),
        ],
      ),
    );
  }
}

class _BankOptionRow extends StatelessWidget {
  const _BankOptionRow({required this.bank, required this.onTap});

  final BankOption bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  bank.name,
                  style: typography.body14.copyWith(color: colors.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
