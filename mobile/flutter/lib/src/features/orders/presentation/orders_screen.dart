import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/orders/presentation/orders_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// C8 — orders list + detail (Orders tab). Placeholder until the screens
/// wave.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(ordersViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabOrders)),
      body: state.when(
        data: (_) => SkeletonPlaceholder(
          icon: Icons.receipt_long_outlined,
          title: l10n.tabOrders,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
