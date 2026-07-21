import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent five-tab shell — Home · Explore · ➕ · Orders · Profile
/// (pages.md Part C; design.md §3) — hosting the StatefulShellRoute's
/// branch navigators. Material icons stand in until the design wave lands
/// the Lucide-based C-series tab-bar module (design.md §2 iconography).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the active tab pops that branch back to its root —
          // the fix for the legacy back-at-root re-push chains (CV-7).
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: l10n.tabExplore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_box_outlined),
            selectedIcon: const Icon(Icons.add_box),
            label: l10n.tabCreate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.tabOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
