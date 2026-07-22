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
    required this.onCreate,
    this.ordersBadge,
    super.key,
  });

  /// Branch order ↔ tab mapping: ➕ is an entry GESTURE with no branch
  /// behind it (the `/create` placeholder was dropped — canvas-first
  /// ruling 2026-07-22: no pages.md spec, no canvas frame), so the four
  /// shell branches skip [AppTab.create] while the bar keeps its five
  /// canvas slots.
  static const List<AppTab> _branchTabs = <AppTab>[
    AppTab.home,
    AppTab.explore,
    AppTab.orders,
    AppTab.profile,
  ];

  final StatefulNavigationShell navigationShell;

  /// ➕ tab gesture (pages.md Part C: the customer branch pushes the
  /// full-screen C6 capture flow over the shell; the designer composer
  /// arrives with its own canvas frames).
  final VoidCallback onCreate;

  /// MI-16 Orders-tab badge count (pass-through to the AppTabBar axis).
  final int? ordersBadge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppTabBar(
        active: _branchTabs[navigationShell.currentIndex],
        ordersBadge: ordersBadge,
        onSelect: (tab) {
          if (tab == AppTab.create) {
            onCreate();
            return;
          }
          final branch = _branchTabs.indexOf(tab);
          navigationShell.goBranch(
            branch,
            // Re-tapping the active tab pops that branch back to its root
            // — the fix for the legacy back-at-root re-push chains (CV-7).
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
