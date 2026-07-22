import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/presentation/orders_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The [Decided 2026-07-16] status → pill mapping, shared by the C8 list
/// and detail chips.
StatusPillValue statusPillOf(OrderStatus status) => switch (status) {
  OrderStatus.requested => StatusPillValue.requested,
  OrderStatus.quoted => StatusPillValue.quoted,
  OrderStatus.paid => StatusPillValue.paid,
  OrderStatus.inProgress => StatusPillValue.inProgress,
  OrderStatus.shipped => StatusPillValue.shipped,
  OrderStatus.delivered => StatusPillValue.delivered,
  OrderStatus.refunded => StatusPillValue.refunded,
  OrderStatus.declined => StatusPillValue.declined,
  OrderStatus.disputed => StatusPillValue.disputed,
  OrderStatus.cancelled => StatusPillValue.cancelled,
};

/// C8 — orders list (pages.md: = B3 adapted): role tabs where the viewer
/// has a designer side, RequestCard rows with the ten-state pills, and a
/// contextual action per state. All actions resolve on the detail screen
/// — the single action surface.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderRole _role = OrderRole.customer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(ordersViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(kind: AppTopBarKind.sub, title: l10n.tabOrders),
      body: switch (state) {
        AsyncData(:final value) => _OrdersBody(
          orders: value,
          role: _role,
          onRole: (role) => setState(() => _role = role),
        ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const _OrdersSkeleton(),
      },
    );
  }
}

/// The C8-orders-loading frame: rounded row blocks.
class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<AppRadii>()!;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(radii.card),
        child: const SizedBox(height: 84, child: Skeleton()),
      ),
    );
  }
}

class _OrdersBody extends ConsumerWidget {
  const _OrdersBody({
    required this.orders,
    required this.role,
    required this.onRole,
  });

  final List<Order> orders;
  final OrderRole role;
  final ValueChanged<OrderRole> onRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Role tabs render only when a designer side exists (pages.md B3:
    // "designer tab only when creator profile enabled" — the seeded §6
    // user is customer-only, so she sees the plain list).
    final hasDesignerSide = orders.any(
      (order) => order.viewerRole == OrderRole.designer,
    );
    final visible = <Order>[
      for (final order in orders)
        if (!hasDesignerSide || order.viewerRole == role) order,
    ];

    return Column(
      children: <Widget>[
        if (hasDesignerSide) _RoleTabs(role: role, onRole: onRole),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: EmptyState(
                      kind: EmptyStateKind.orders,
                      onCta: () => const ExploreRoute().go(context),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: ref.read(ordersViewModelProvider.notifier).refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) =>
                        _OrderCard(order: visible[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RoleTabs extends StatelessWidget {
  const _RoleTabs({required this.role, required this.onRole});

  final OrderRole role;
  final ValueChanged<OrderRole> onRole;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    Widget tab(OrderRole value, String label) {
      final active = role == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: active,
          child: GestureDetector(
            onTap: () => onRole(value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? colors.text : colors.border,
                    width: active ? 2 : 1,
                  ),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: typography.body14.copyWith(
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? colors.text : colors.text2,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        tab(OrderRole.customer, l10n.ordersAsCustomer),
        tab(OrderRole.designer, l10n.ordersAsDesigner),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  /// The contextual list action per state × role (canvas C8-orders).
  (String, ButtonKind)? _action(BuildContext context) {
    final l10n = context.l10n;
    if (order.viewerRole == OrderRole.customer) {
      return switch (order.status) {
        OrderStatus.quoted when order.quoteCents != null => (
          l10n.ordersPayCta(formatNaira(order.quoteCents!)),
          ButtonKind.gradientPrimary,
        ),
        OrderStatus.shipped => (
          l10n.ordersConfirmDelivery,
          ButtonKind.gradientPrimary,
        ),
        OrderStatus.paid ||
        OrderStatus.inProgress ||
        OrderStatus.disputed => (l10n.ordersViewUpdates, ButtonKind.quiet),
        _ => (l10n.ordersViewOrder, ButtonKind.quiet),
      };
    }
    return switch (order.status) {
      OrderStatus.requested => (
        l10n.ordersSendQuote,
        ButtonKind.gradientPrimary,
      ),
      _ => (l10n.ordersViewOrder, ButtonKind.quiet),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final action = _action(context);
    final counterparty = order.viewerRole == OrderRole.customer
        ? l10n.ordersDesignerLine(order.designer.username)
        : l10n.ordersCustomerLine(order.customer.username);
    final amount = order.displayAmountCents;

    void open() => OrderDetailRoute(id: order.id).push<void>(context);

    return Semantics(
      button: true,
      label: '${order.orderNumber} ${order.post.caption}',
      child: GestureDetector(
        onTap: open,
        child: Container(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.caption13.copyWith(
                        color: colors.text2,
                      ),
                    ),
                    if (amount != null) ...<Widget>[
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  StatusPill(status: statusPillOf(order.status)),
                  if (action != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Button(
                      label: action.$1,
                      kind: action.$2,
                      size: ButtonSize.sm,
                      onPressed: open,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
