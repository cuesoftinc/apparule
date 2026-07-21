import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:flutter/material.dart';

/// C3 — explore/search (Explore tab). Placeholder until the screens
/// wave; static because it has no state to orchestrate yet.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabExplore)),
      body: SkeletonPlaceholder(
        icon: Icons.search_outlined,
        title: l10n.tabExplore,
      ),
    );
  }
}
