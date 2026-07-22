import 'package:apparule/src/core/ui/tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent five-tab shell — Home · Explore · ➕ · Orders · Profile
/// (pages.md Part C; design.md §3) — hosting the StatefulShellRoute's
/// branch navigators over the C-series AppTabBar module (49:384; the
/// design wave's replacement for the Material-icon stand-in).
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    this.onCreate,
    this.ordersBadge,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  /// ➕ tab interception — the create tab is an entry GESTURE, not a
  /// branch switch, when the router supplies this (pages.md Part C: the
  /// customer branch pushes the full-screen C6 capture flow over the
  /// shell). `null` falls back to activating the branch.
  final VoidCallback? onCreate;

  /// MI-16 Orders-tab badge count (pass-through to the AppTabBar axis).
  final int? ordersBadge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppTabBar(
        active: AppTab.values[navigationShell.currentIndex],
        ordersBadge: ordersBadge,
        onSelect: (tab) {
          if (tab == AppTab.create && onCreate != null) {
            onCreate!();
            return;
          }
          navigationShell.goBranch(
            tab.index,
            // Re-tapping the active tab pops that branch back to its root
            // — the fix for the legacy back-at-root re-push chains (CV-7).
            initialLocation: tab.index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
