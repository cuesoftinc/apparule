import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// C9 — own profile (Profile tab). Placeholder until the screens wave.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(profileViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: state.when(
        data: (_) => SkeletonPlaceholder(
          icon: Icons.person_outline,
          title: l10n.tabProfile,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
