import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:flutter/material.dart';

/// The ➕ tab entry — Explore→Request for customers, the B5-parity post
/// composer for designers (mobile-implementation.md §5). Placeholder; the
/// role branch arrives with the screens wave.
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabCreate)),
      body: SkeletonPlaceholder(
        icon: Icons.add_box_outlined,
        title: l10n.tabCreate,
      ),
    );
  }
}
