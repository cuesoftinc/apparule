import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/measurements/presentation/vault_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// C7 — the measurement vault. Placeholder until the capture/vault wave.
class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(vaultViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vaultTitle)),
      body: state.when(
        data: (_) => SkeletonPlaceholder(
          icon: Icons.straighten_outlined,
          title: l10n.vaultTitle,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
