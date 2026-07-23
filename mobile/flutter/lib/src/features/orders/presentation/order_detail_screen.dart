import 'dart:async' show unawaited;

import 'package:apparule/src/core/async/run_action.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/payment_box.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/core/ui/timeline_connector.dart';
import 'package:apparule/src/core/ui/typing_bubble.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/presentation/order_action_sheets.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_view_model.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C8 detail (pages.md B3): outfit summary · timeline (MI-14, the
/// TimelineConnector ladder with the terminal-error rung) · measurement
/// snapshot (immutable) · payment box (MI-15: paying state + just-paid
/// escrow explainer) · role-scoped actions (danger ladder: quiet-danger
/// rows, armed sheet confirms, every transition through `runAction`) ·
/// thread (MI-17 typing hold-back, MI-18 optimistic send) with composer.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderDetailViewModelProvider(orderId));

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: state.value?.order.post.caption ?? '',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            // Deep-linked (push notification) with an empty stack.
            const OrdersRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value) => _OrderDetailBody(state: value),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({required this.state});

  final OrderDetailState state;

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  /// D42: the payment box's "View dispute" / "Respond to dispute" CTA
  /// scrolls the dispute section on stage.
  final GlobalKey _disputeSectionKey = GlobalKey();

  Order get _order => widget.state.order;

  OrderDetailViewModel get _viewModel =>
      ref.read(orderDetailViewModelProvider(_order.id).notifier);

  /// D06/D42: the quiet payment-box CTA per state — requote for the
  /// quoted designer, payout detail for the released designer, and the
  /// dispute section for the frozen box.
  Future<void> _onPaymentAction(PaymentBoxState paymentState) async {
    switch (paymentState) {
      case PaymentBoxState.quoted:
        await _requote();
      case PaymentBoxState.released:
        await const EarningsRoute().push<void>(context);
      case PaymentBoxState.disputeFrozen:
        if (_disputeSectionKey.currentContext case final target?) {
          await Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 200),
          );
        }
      case PaymentBoxState.paying ||
          PaymentBoxState.escrowHeld ||
          PaymentBoxState.refunded:
        break; // No quiet CTA in these states.
    }
  }

  /// D06: requote while quoted — the sheet opens prefilled with the
  /// current amount and `quote()` replaces it without a transition
  /// (flows/designer.md §2; web "Edit quote" parity).
  Future<void> _requote() async {
    final result = await showQuoteSheet(
      context,
      suggestedCents: _order.quoteCents ?? _order.budgetCents,
    );
    if (result != null && mounted) {
      await runAction(
        context,
        () => _viewModel.sendQuote(result.$1, dueAt: result.$2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final order = state.order;
    final paymentState = state.paying
        ? PaymentBoxState.paying
        : _paymentStateOf(order);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SummaryCard(order: order),
              const SizedBox(height: 16),
              _Timeline(order: order),
              if (paymentState case final paymentState?) ...<Widget>[
                const SizedBox(height: 16),
                PaymentBox(
                  state: paymentState,
                  role: order.viewerRole == OrderRole.designer
                      ? PaymentRole.designer
                      : PaymentRole.customer,
                  quoteCents: order.quoteCents ?? 0,
                  // MI-15 (D64): the explainer expands on the just-paid
                  // moment only — never on every re-entry to a paid order.
                  showEscrowExplainer:
                      state.justPaid &&
                      paymentState == PaymentBoxState.escrowHeld &&
                      order.viewerRole == OrderRole.customer,
                  onPay: order.viewerRole == OrderRole.customer
                      ? () => unawaited(
                          runAction(
                            context,
                            _viewModel.pay,
                            failureText: context.l10n.payFailedToast,
                          ),
                        )
                      : null,
                  onAction: (_) => unawaited(_onPaymentAction(paymentState)),
                ),
              ],
              const SizedBox(height: 16),
              _SnapshotCard(order: order),
              // D43: the decline reason / open dispute surface to the
              // counterparty (web OrderDetailView parity).
              if (order.declineReason case final reason?) ...<Widget>[
                const SizedBox(height: 16),
                _DeclinedNote(reason: reason, note: order.declineNote),
              ],
              if (order.dispute case final dispute?) ...<Widget>[
                const SizedBox(height: 16),
                _DisputeNote(key: _disputeSectionKey, dispute: dispute),
              ],
              const SizedBox(height: 16),
              _Actions(order: order, viewModel: _viewModel),
              if (state.messages.isNotEmpty) const SizedBox(height: 8),
              for (final entry in state.messages)
                _MessageBubble(
                  entry: entry,
                  onRetry: entry.sendState == ThreadSendState.failed
                      ? () => unawaited(
                          _viewModel.retryMessage(entry.message.id),
                        )
                      : null,
                ),
              // MI-17 (D13): the counterparty "responding…" pulse while
              // the scripted reply is held back.
              if (state.typing)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TypingBubble(),
                  ),
                ),
            ],
          ),
        ),
        // Threads stay open from `requested` until 30 days after the
        // terminal state (order-lifecycle.md §5) — every seeded terminal
        // order sits inside that window.
        _Composer(order: order, viewModel: _viewModel),
      ],
    );
  }

  /// Order state → MI-15 payment box cell; null renders no box
  /// (requested/declined/cancelled — nothing moved yet).
  static PaymentBoxState? _paymentStateOf(Order order) {
    if (order.status == OrderStatus.quoted && order.quoteCents != null) {
      return PaymentBoxState.quoted;
    }
    return switch (order.payment?.state) {
      PaymentState.held when order.status == OrderStatus.disputed =>
        PaymentBoxState.disputeFrozen,
      PaymentState.held => PaymentBoxState.escrowHeld,
      PaymentState.released => PaymentBoxState.released,
      PaymentState.refunded => PaymentBoxState.refunded,
      null => null,
    };
  }
}

/// D43 — "Declined: {reason}" (plus the designer's optional note when one
/// was left) so the customer sees WHY, not just a bare pill.
class _DeclinedNote extends StatelessWidget {
  const _DeclinedNote({required this.reason, this.note});

  final DeclineReason reason;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.orderDeclinedReason(declineReasonLabel(context, reason)),
          style: typography.body14.copyWith(color: colors.text2),
        ),
        if (note case final note?) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            '“$note”',
            style: typography.body14.copyWith(color: colors.text2),
          ),
        ],
      ],
    );
  }
}

/// D43 — the open dispute's reason + detail (web parity: "Dispute open
/// ({reason}) — {detail}. Support resolves disputes…").
class _DisputeNote extends StatelessWidget {
  const _DisputeNote({required this.dispute, super.key});

  final OrderDispute dispute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final detail = dispute.detail;
    return Text(
      l10n.orderDisputeOpen(
        disputeReasonLabel(context, dispute.reason),
        // The web template strips any trailing period — its own sentence
        // punctuation follows.
        detail == null ? '' : ' — ${detail.replaceAll(RegExp(r'\.$'), '')}',
      ),
      style: typography.body14.copyWith(color: colors.text2),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    // The counterparty reference navigates to their C9 profile (web
    // OrderDetailView parity: `/dashboard/{counterparty}` link).
    final counterpartyUsername = order.viewerRole == OrderRole.customer
        ? order.designer.username
        : order.customer.username;
    final counterparty = order.viewerRole == OrderRole.customer
        ? l10n.ordersDesignerLine(order.designer.username)
        : l10n.ordersCustomerLine(order.customer.username);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElev,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(radii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(radii.card),
            child: Image(
              image: seedMediaImage(order.post.thumbUrl),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  order.post.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  // One node (the StoryRailItem pattern) — the line's
                  // text is visual; the node announces the affordance.
                  container: true,
                  excludeSemantics: true,
                  label: 'View $counterpartyUsername profile',
                  button: true,
                  onTap: () => PublicProfileRoute(
                    username: counterpartyUsername,
                  ).push<void>(context),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => PublicProfileRoute(
                      username: counterpartyUsername,
                    ).push<void>(context),
                    child: Text(
                      counterparty,
                      style: typography.caption13.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ),
                ),
                if (order.displayAmountCents case final amount?) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    formatNaira(amount),
                    style: typography.body14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusPill(status: statusPillOf(order.status)),
        ],
      ),
    );
  }
}

/// MI-14 — the vertical event timeline over the TimelineConnector ladder
/// (D41): done dots in success, the current event on the accent gradient
/// with the §4 pulse, connectors drawing 400ms, the next happy-path step
/// pending (hollow), and declined/disputed/refunded/cancelled events on
/// the terminal-error rung — never a green ✓ (web OrderDetailView
/// ERROR_KINDS parity).
class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final Order order;

  static const List<OrderStatus> _happyPath = <OrderStatus>[
    OrderStatus.requested,
    OrderStatus.quoted,
    OrderStatus.paid,
    OrderStatus.inProgress,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  /// Event kinds that wear the terminal-error dot (web ERROR_KINDS).
  static const Set<String> _errorKinds = <String>{
    'declined',
    'disputed',
    'refunded',
    'cancelled',
  };

  /// Statuses whose latest event is settled — `done`, not `current`
  /// (web TERMINAL; disputed stays `current`, it can still move).
  static const Set<OrderStatus> _terminal = <OrderStatus>{
    OrderStatus.delivered,
    OrderStatus.refunded,
    OrderStatus.declined,
    OrderStatus.cancelled,
  };

  /// The web dot mapping, verbatim: error kinds are terminal-error at any
  /// position; the last event is `current` unless the order is settled.
  TimelineDotState _dotOf(OrderEvent event, {required bool lastEvent}) {
    if (_errorKinds.contains(event.kind)) {
      return TimelineDotState.terminalError;
    }
    if (!lastEvent) return TimelineDotState.done;
    return _terminal.contains(order.status)
        ? TimelineDotState.done
        : TimelineDotState.current;
  }

  String _labelOf(BuildContext context, OrderEvent event) {
    final l10n = context.l10n;
    return switch (event.kind) {
      'requested' => l10n.timelineRequested,
      'quoted' =>
        order.quoteCents == null
            ? l10n.timelineQuotedPending
            : l10n.timelineQuoted(formatNaira(order.quoteCents!)),
      'paid' => l10n.timelinePaid,
      'in_progress' => l10n.timelineInProgress,
      'shipped' =>
        order.tracking == null
            ? l10n.timelineShipped
            : l10n.timelineShippedTracking(order.tracking!),
      'delivered' => l10n.timelineDelivered,
      'disputed' => l10n.timelineDisputed,
      'declined' => l10n.timelineDeclined,
      'refunded' => l10n.timelineRefunded,
      'cancelled' => l10n.timelineCancelled,
      final other => other,
    };
  }

  String? _pendingLabel(BuildContext context) {
    final l10n = context.l10n;
    final index = _happyPath.indexOf(order.status);
    if (index < 0 || index == _happyPath.length - 1) return null;
    return switch (_happyPath[index + 1]) {
      OrderStatus.quoted => l10n.timelineQuotedPending,
      OrderStatus.paid => l10n.timelinePaid,
      OrderStatus.inProgress => l10n.timelineInProgress,
      OrderStatus.shipped => l10n.timelineShipped,
      OrderStatus.delivered => l10n.timelineDelivered,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final pending = _pendingLabel(context);

    Widget row({
      required TimelineDotState dot,
      required String label,
      required String meta,
      required bool last,
      bool emphasize = false,
    }) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // MI-14 (D41): the 400ms connector draw + current-dot pulse
            // live in the shared primitive.
            TimelineConnector(state: dot, last: last),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: typography.body14.copyWith(
                        fontWeight: emphasize
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: typography.micro12.copyWith(
                        color: colors.text2,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final (index, event) in order.events.indexed)
          row(
            dot: _dotOf(event, lastEvent: index == order.events.length - 1),
            label: _labelOf(context, event),
            meta: formatDateClock(event.createdAt),
            emphasize: index == order.events.length - 1,
            last: index == order.events.length - 1 && pending == null,
          ),
        if (pending != null)
          row(
            dot: TimelineDotState.upcoming,
            label: pending,
            meta: l10n.timelinePending,
            last: true,
          ),
      ],
    );
  }
}

/// The immutable measurement snapshot (order-lifecycle.md §1/§2: the
/// designer sees ONLY this frozen copy, and only inside this order).
class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    const tnum = <FontFeature>[FontFeature.tabularFigures()];

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
          Row(
            children: <Widget>[
              Icon(LucideIcons.ruler, size: 18, color: colors.text2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.orderSnapshotHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body16SemiBold.copyWith(
                    color: colors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final measurement in order.snapshot.measurements)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      humanizeMeasureName(measurement.name),
                      style: typography.body14.copyWith(color: colors.text2),
                    ),
                  ),
                  Text(
                    formatCm(measurement.valueCm),
                    style: typography.body14.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                      fontFeatures: tnum,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            l10n.orderSnapshotFrozen(formatDayMonth(order.createdAt)),
            style: typography.micro12.copyWith(color: colors.text2),
          ),
        ],
      ),
    );
  }
}

/// Role-scoped actions per lifecycle state (order-lifecycle.md §2).
/// Danger ladder (CLASS 5): the rows here are quiet(-danger) rungs;
/// every irreversible transition passes an ARMED sheet first — and every
/// transition runs inside `runAction`, so a race/double-tap surfaces as
/// the failure toast instead of a silent StateError (D39).
class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.viewModel});

  final Order order;
  final OrderDetailViewModel viewModel;

  Future<void> _dispute(BuildContext context) async {
    final result = await showDisputeSheet(context);
    if (result != null && context.mounted) {
      await runAction(
        context,
        () => viewModel.openDispute(result.$1, detail: result.$2),
      );
    }
  }

  Future<void> _decline(BuildContext context) async {
    final result = await showDeclineSheet(context);
    if (result != null && context.mounted) {
      // D04: the optional note rides the repository call.
      await runAction(
        context,
        () => viewModel.decline(result.$1, note: result.$2),
      );
    }
  }

  Future<void> _quote(BuildContext context) async {
    final result = await showQuoteSheet(
      context,
      suggestedCents: order.budgetCents,
    );
    if (result != null && context.mounted) {
      await runAction(
        context,
        () => viewModel.sendQuote(result.$1, dueAt: result.$2),
      );
    }
  }

  /// D08: confirming delivery releases the payout irreversibly — the
  /// armed sheet spells that out before anything moves (web ConfirmSheet
  /// copy).
  Future<void> _confirmDelivery(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showOrderConfirmSheet(
      context,
      title: l10n.confirmDeliveryTitle,
      body: l10n.confirmDeliveryBody(order.designer.username),
      confirmLabel: l10n.ordersConfirmDelivery,
    );
    if ((confirmed ?? false) && context.mounted) {
      await runAction(context, viewModel.confirmDelivery);
    }
  }

  /// D09: withdraw (requested) / reject quote (quoted) — one-tap cancel
  /// becomes a destructive armed sheet, with the quoted state named for
  /// what it is (web "Reject quote" parity).
  Future<void> _withdraw(BuildContext context) async {
    final l10n = context.l10n;
    final quoted = order.status == OrderStatus.quoted;
    final confirmed = await showOrderConfirmSheet(
      context,
      title: quoted ? l10n.rejectQuoteSheetTitle : l10n.withdrawSheetTitle,
      body: quoted ? l10n.rejectQuoteSheetBody : l10n.withdrawSheetBody,
      confirmLabel: quoted ? l10n.orderRejectQuote : l10n.orderWithdraw,
      destructive: true,
    );
    if ((confirmed ?? false) && context.mounted) {
      await runAction(context, viewModel.withdraw);
    }
  }

  /// D10: mark shipped through the ship sheet — tracking is optional but
  /// finally ENTERABLE (web ShipSheet parity).
  Future<void> _ship(BuildContext context) async {
    final result = await showShipSheet(context);
    if (result != null && context.mounted) {
      await runAction(
        context,
        () => viewModel.ship(tracking: result.tracking),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final customer = order.viewerRole == OrderRole.customer;
    final children = <Widget>[];

    if (customer) {
      if (order.status == OrderStatus.shipped) {
        children.add(
          Button(
            label: l10n.ordersConfirmDelivery,
            expand: true,
            onPressed: () => unawaited(_confirmDelivery(context)),
          ),
        );
      }
      if (order.status == OrderStatus.requested ||
          order.status == OrderStatus.quoted) {
        // Row-level rung of the danger ladder: quiet-danger, never a
        // bare destructive fill outside an armed sheet.
        children.add(
          Button(
            label: order.status == OrderStatus.quoted
                ? l10n.orderRejectQuote
                : l10n.orderWithdraw,
            kind: ButtonKind.quietDanger,
            expand: true,
            onPressed: () => unawaited(_withdraw(context)),
          ),
        );
      }
    } else {
      if (order.status == OrderStatus.requested) {
        children
          ..add(
            Button(
              label: l10n.ordersSendQuote,
              expand: true,
              onPressed: () => unawaited(_quote(context)),
            ),
          )
          ..add(
            Button(
              label: l10n.declineSubmit,
              kind: ButtonKind.quietDanger,
              expand: true,
              onPressed: () => unawaited(_decline(context)),
            ),
          );
      }
      if (order.status == OrderStatus.paid) {
        children.add(
          Button(
            label: l10n.orderStartWork,
            kind: ButtonKind.quiet,
            expand: true,
            onPressed: () =>
                unawaited(runAction(context, viewModel.startProgress)),
          ),
        );
      }
      if (order.status == OrderStatus.inProgress) {
        children.add(
          Button(
            label: l10n.orderMarkShipped,
            kind: ButtonKind.quiet,
            expand: true,
            onPressed: () => unawaited(_ship(context)),
          ),
        );
      }
    }

    // Dispute entry — either party, inside the dispute window
    // (order-lifecycle.md §1: paid/in_progress/shipped).
    final disputable = switch (order.status) {
      OrderStatus.paid || OrderStatus.inProgress || OrderStatus.shipped => true,
      _ => false,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final child in children)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child,
          ),
        if (disputable)
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => unawaited(_dispute(context)),
              child: Text(
                l10n.orderSomethingWrong,
                style: typography.body14.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.link,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// MI-17 thread bubble — own messages right on the text fill, the
/// counterparty left on the elevated surface. Carries the MI-18 send
/// ladder (D40): `sending` dims the bubble, `failed` swaps the timestamp
/// for the retry affordance so the text is never silently lost.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry, this.onRetry});

  final ThreadEntry entry;

  /// Non-null only for failed rows — tapping re-sends the same body.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = entry.message;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final own = message.own;

    final meta = switch (entry.sendState) {
      ThreadSendState.sending => Text(
        l10n.threadSending,
        style: typography.micro12.copyWith(color: colors.text2),
      ),
      ThreadSendState.failed => Semantics(
        button: true,
        child: GestureDetector(
          onTap: onRetry,
          child: Text(
            l10n.threadFailedRetry,
            style: typography.micro12.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.error,
            ),
          ),
        ),
      ),
      ThreadSendState.sent => Text(
        formatClock(message.createdAt),
        style: typography.micro12.copyWith(color: colors.text2),
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: own
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          Opacity(
            // MI-18: the optimistic bubble reads in-flight until the
            // server echo lands.
            opacity: entry.sendState == ThreadSendState.sending ? 0.6 : 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: own ? colors.text : colors.bgElev,
                  border: own ? null : Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(radii.card * 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (message.imageUrl case final image?) ...<Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(radii.card),
                        child: Image(
                          image: seedMediaImage(image),
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      message.body,
                      style: typography.body14.copyWith(
                        color: own ? colors.bg : colors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          meta,
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.order, required this.viewModel});

  final Order order;
  final OrderDetailViewModel viewModel;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text;
    if (body.trim().isEmpty) return;
    // MI-18 (D40): the optimistic bubble takes custody of the text in
    // the same frame (web parity — the composer clears at send; a failed
    // send keeps the text alive in the failed bubble with retry, so
    // nothing is ever silently lost).
    _controller.clear();
    await widget.viewModel.sendMessage(body);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final counterparty = widget.order.viewerRole == OrderRole.customer
        ? widget.order.designer.username
        : widget.order.customer.username;

    OutlineInputBorder border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.card),
      borderSide: BorderSide(color: colors.border),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  style: typography.body14.copyWith(color: colors.text),
                  decoration: InputDecoration(
                    hintText: l10n.orderThreadHint(counterparty),
                    hintStyle: typography.body14.copyWith(
                      color: colors.text2,
                    ),
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
                ),
              ),
              Semantics(
                label: l10n.orderThreadSendLabel,
                button: true,
                child: InkResponse(
                  onTap: _send,
                  radius: 22,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      LucideIcons.send,
                      size: 22,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
