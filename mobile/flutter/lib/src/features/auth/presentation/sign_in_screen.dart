import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// C1 — the single Google-CTA auth screen (flows/auth.md §5). Placeholder
/// until the auth cutover wave.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(signInViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: state.when(
        data: (_) => SkeletonPlaceholder(
          icon: Icons.login_outlined,
          title: l10n.signInTitle,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
