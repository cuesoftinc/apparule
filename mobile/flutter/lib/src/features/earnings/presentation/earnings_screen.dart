import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// C14 — earnings & payouts. Placeholder until the screens wave.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(earningsViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.earningsTitle)),
      body: state.when(
        data: (_) => SkeletonPlaceholder(
          icon: Icons.payments_outlined,
          title: l10n.earningsTitle,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
