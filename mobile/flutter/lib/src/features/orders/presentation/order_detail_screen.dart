import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/payment_box.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/domain/thread_message.dart';
import 'package:apparule/src/features/orders/presentation/order_action_sheets.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_view_model.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C8 detail (pages.md B3): outfit summary · timeline (MI-14) ·
/// measurement snapshot (immutable) · payment box (MI-15) · role-scoped
/// actions (danger ladder: quiet-danger rows, filled-destructive sheet
/// confirms) · thread (MI-17) with composer.
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
        AsyncData(:final value) => _OrderDetailBody(
          order: value.order,
          messages: value.messages,
        ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.order, required this.messages});

  final Order order;
  final List<ThreadMessage> messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      orderDetailViewModelProvider(order.id).notifier,
    );

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SummaryCard(order: order),
              const SizedBox(height: 16),
              _Timeline(order: order),
              if (_paymentStateOf(order) case final paymentState?) ...<Widget>[
                const SizedBox(height: 16),
                PaymentBox(
                  state: paymentState,
                  role: order.viewerRole == OrderRole.designer
                      ? PaymentRole.designer
                      : PaymentRole.customer,
                  quoteCents: order.quoteCents ?? 0,
                  // MI-15: the escrow explainer expands on first payment.
                  showEscrowExplainer:
                      order.status == OrderStatus.paid &&
                      order.viewerRole == OrderRole.customer,
                  onPay: viewModel.pay,
                ),
              ],
              const SizedBox(height: 16),
              _SnapshotCard(order: order),
              const SizedBox(height: 16),
              _Actions(order: order, viewModel: viewModel),
              if (messages.isNotEmpty) const SizedBox(height: 8),
              for (final message in messages) _MessageBubble(message: message),
            ],
          ),
        ),
        // Threads stay open from `requested` until 30 days after the
        // terminal state (order-lifecycle.md §5) — every seeded terminal
        // order sits inside that window.
        _Composer(order: order, viewModel: viewModel),
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
                Text(
                  counterparty,
                  style: typography.caption13.copyWith(color: colors.text2),
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

/// MI-14 — the vertical event timeline: done dots in success, the
/// current event on the accent gradient, the next happy-path step
/// pending (hollow).
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
      required Widget dot,
      required String label,
      required String meta,
      required bool last,
      bool emphasize = false,
    }) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Column(
              children: <Widget>[
                dot,
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: colors.border),
                  ),
              ],
            ),
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

    Widget doneDot() => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: colors.success,
        shape: BoxShape.circle,
      ),
    );
    Widget currentDot() => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        gradient: colors.accentGradient,
        shape: BoxShape.circle,
      ),
    );
    Widget pendingDot() => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.border, width: 2),
      ),
    );

    return Column(
      children: <Widget>[
        for (final (index, event) in order.events.indexed)
          row(
            dot: index == order.events.length - 1 ? currentDot() : doneDot(),
            label: _labelOf(context, event),
            meta: formatDateClock(event.createdAt),
            emphasize: index == order.events.length - 1,
            last: index == order.events.length - 1 && pending == null,
          ),
        if (pending != null)
          row(
            dot: pendingDot(),
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
class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.viewModel});

  final Order order;
  final OrderDetailViewModel viewModel;

  Future<void> _dispute(BuildContext context) async {
    final result = await showDisputeSheet(context);
    if (result != null) {
      await viewModel.openDispute(result.$1, detail: result.$2);
    }
  }

  Future<void> _decline(BuildContext context) async {
    final reason = await showDeclineSheet(context);
    if (reason != null) await viewModel.decline(reason);
  }

  Future<void> _quote(BuildContext context) async {
    final result = await showQuoteSheet(
      context,
      suggestedCents: order.budgetCents,
    );
    if (result != null) {
      await viewModel.sendQuote(result.$1, dueAt: result.$2);
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
            onPressed: viewModel.confirmDelivery,
          ),
        );
      }
      if (order.status == OrderStatus.requested ||
          order.status == OrderStatus.quoted) {
        // Row-level rung of the danger ladder: quiet-danger, never a
        // bare destructive fill outside an armed sheet.
        children.add(
          Button(
            label: l10n.orderWithdraw,
            kind: ButtonKind.quietDanger,
            expand: true,
            onPressed: viewModel.withdraw,
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
              onPressed: () => _quote(context),
            ),
          )
          ..add(
            Button(
              label: l10n.declineSubmit,
              kind: ButtonKind.quietDanger,
              expand: true,
              onPressed: () => _decline(context),
            ),
          );
      }
      if (order.status == OrderStatus.paid) {
        children.add(
          Button(
            label: l10n.orderStartWork,
            kind: ButtonKind.quiet,
            expand: true,
            onPressed: viewModel.startProgress,
          ),
        );
      }
      if (order.status == OrderStatus.inProgress) {
        children.add(
          Button(
            label: l10n.orderMarkShipped,
            kind: ButtonKind.quiet,
            expand: true,
            onPressed: viewModel.ship,
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
              onTap: () => _dispute(context),
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
/// counterparty left on the elevated surface.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ThreadMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final own = message.own;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: own
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          ConstrainedBox(
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
          const SizedBox(height: 2),
          Text(
            formatClock(message.createdAt),
            style: typography.micro12.copyWith(color: colors.text2),
          ),
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
