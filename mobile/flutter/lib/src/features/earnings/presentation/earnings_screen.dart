import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/banner.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/earnings_summary.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/ui/transaction_row.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/earnings/domain/earnings.dart';
import 'package:apparule/src/features/earnings/domain/earnings_exception.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C14 — Earnings & payouts (canvas 267:8613; pages.md B9): the balance
/// explainer, EarningsSummary cards (available / in escrow), the payout-
/// account status line (verified chip · Change → C13, or Add), and the
/// Recent-activity TransactionRow ledger with tabular figures. States:
/// non-designer empty (→ C13), loading skeleton, KYC-lapse banner,
/// empty ledger, populated. The ⋯ menu requests an early payout — the
/// fake MOVES the balance into a processing row.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(earningsViewModelProvider);
    final status = ref.watch(designerStatusProvider).value;

    Future<void> requestPayout() async {
      final confirmed = await Sheet.show<bool>(
        context,
        title: l10n.earningsRequestPayoutTitle,
        child: const _RequestPayoutConfirm(),
      );
      if (confirmed ?? false) {
        await ref.read(earningsViewModelProvider.notifier).requestPayout();
      }
    }

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.earningsTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const ProfileRoute().go(context);
          }
        },
        trailing: switch (state) {
          AsyncData(:final value) when value.availableCents > 0 => IconButton(
            icon: const Icon(LucideIcons.ellipsis, size: 22),
            tooltip: l10n.earningsRequestPayoutTitle,
            onPressed: requestPayout,
          ),
          _ => null,
        },
      ),
      body: switch (state) {
        AsyncData(:final value) => _EarningsBody(
          earnings: value,
          status: status,
        ),
        AsyncError(:final error)
            when error is EarningsException &&
                error.code == EarningsErrorCode.designerProfileRequired =>
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EmptyState(
                kind: EmptyStateKind.orders,
                line: l10n.earningsBecomeDesignerLine,
                ctaLabel: l10n.settingsBecomeDesigner,
                onCta: () =>
                    const DesignerOnboardingRoute().push<void>(context),
              ),
            ),
          ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => ListView(
          padding: const EdgeInsets.all(16),
          children: const <Widget>[
            Skeleton(kind: SkeletonKind.card),
            SizedBox(height: 16),
            Skeleton(),
          ],
        ),
      },
    );
  }
}

class _EarningsBody extends ConsumerWidget {
  const _EarningsBody({required this.earnings, required this.status});

  final Earnings earnings;
  final DesignerStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final account = status?.payoutAccount;
    final now = ref.watch(clockProvider)();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        if (account?.kycState == KycState.lapsed) ...<Widget>[
          AppBanner(
            tone: BannerTone.warn,
            message: l10n.kycLapsedBanner,
            actionLabel: l10n.kycLapsedReverify,
            onAction: () => const PayoutAccountRoute().push<void>(context),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          l10n.earningsExplainer,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
        const SizedBox(height: 16),
        EarningsSummary(
          balanceCents: earnings.availableCents,
          pendingCents: earnings.pendingCents,
          currency: earnings.currency,
        ),
        const SizedBox(height: 16),
        // Canvas 267:8613 status line: "GTBank ••• 4521 — AMARA OKAFOR
        // Verified  Change →".
        if (account != null)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                '${account.bankName} ••• ${account.accountLast4} — '
                '${account.accountName}',
                style: typography.body14.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
              Text(
                switch (account.kycState) {
                  KycState.verified => l10n.payoutStateVerified,
                  KycState.lapsed => l10n.payoutStateLapsed,
                  KycState.pending => l10n.payoutStatePending,
                },
                style: typography.caption13.copyWith(
                  fontWeight: FontWeight.w600,
                  color: switch (account.kycState) {
                    KycState.verified => colors.success,
                    _ => colors.warnText,
                  },
                ),
              ),
              Button(
                label: l10n.earningsChangeAccount,
                kind: ButtonKind.link,
                size: ButtonSize.sm,
                onPressed: () =>
                    const PayoutAccountRoute().push<void>(context),
              ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                l10n.earningsNoAccount,
                style: typography.caption13.copyWith(color: colors.text2),
              ),
              Button(
                label: l10n.earningsAddAccount,
                kind: ButtonKind.link,
                size: ButtonSize.sm,
                onPressed: () =>
                    const PayoutAccountRoute().push<void>(context),
              ),
            ],
          ),
        const SizedBox(height: 24),
        Text(
          l10n.earningsRecentActivity,
          style: typography.title20SemiBold.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 4),
        if (earnings.transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: EmptyState(
              kind: EmptyStateKind.orders,
              line: l10n.earningsEmptyLedger,
              ctaLabel: l10n.earningsEmptyLedgerCta,
              onCta: () => const CreateRoute().go(context),
            ),
          )
        else
          for (final entry in earnings.transactions)
            TransactionRow(
              kind: switch (entry.kind) {
                EarningsEntryKind.payout => TransactionKind.payout,
                EarningsEntryKind.escrowHeld => TransactionKind.escrowHeld,
                EarningsEntryKind.feeLine => TransactionKind.feeLine,
              },
              amountCents: entry.amountCents,
              currency: entry.currency,
              label: entry.label,
              orderNumber: entry.orderNumber,
              providerRef: entry.providerRef,
              dateLabel: now.difference(entry.createdAt).inDays < 1
                  ? l10n.earningsProcessing
                  : formatMonthDay(entry.createdAt),
            ),
      ],
    );
  }
}

/// The ⋯ payout-request confirm — quiet framing, no danger chrome: it
/// moves money to the bank, it doesn't destroy anything.
class _RequestPayoutConfirm extends ConsumerWidget {
  const _RequestPayoutConfirm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final available =
        ref.watch(earningsViewModelProvider).value?.availableCents ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.earningsRequestPayoutBody(formatNaira(available)),
          style: typography.body14.copyWith(color: colors.text2),
        ),
        const SizedBox(height: 16),
        Button(
          label: l10n.earningsRequestPayoutConfirm,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 8),
        Button(
          label: l10n.earningsRequestPayoutCancel,
          kind: ButtonKind.quiet,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
