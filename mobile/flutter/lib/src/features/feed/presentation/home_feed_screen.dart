import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// C2 — the home feed (Home tab). Placeholder until the screens wave.
class HomeFeedScreen extends ConsumerWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(homeFeedViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabHome)),
      body: state.when(
        data: (_) => SkeletonPlaceholder(
          icon: Icons.home_outlined,
          title: l10n.tabHome,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
