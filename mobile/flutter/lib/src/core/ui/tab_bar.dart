import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `TabBar` set's `active` axis (49:384) — the five-tab shell
/// Home · Explore · ➕ · Orders · Profile (pages.md Part C; design.md §3).
enum AppTab {
  home(LucideIcons.house, 'Home'),
  explore(LucideIcons.search, 'Explore'),
  create(LucideIcons.plus, 'Create'),
  orders(LucideIcons.package, 'Orders'),
  profile(LucideIcons.user, 'Profile');

  const AppTab(this.icon, this.semanticLabel);

  /// Lucide glyph per the Figma master (explore = the search glyph).
  final IconData icon;

  /// Named-control canon: the tabs are icon-only, so each carries its
  /// canonical semantics label (web sibling's `aria-label`).
  final String semanticLabel;
}

/// AppTabBar — the Figma `TabBar` set (49:384; file name canonical, class
/// renamed off Material's `TabBar`). Axes: `active` ×5 · `badge`
/// none/count (Orders only, MI-16 pop). Icon-only tabs at 56px; the
/// centre create tab renders the 40px gradient FAB; the active tab wears
/// the 4px gradient dot.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.active,
    required this.onSelect,
    this.ordersBadge,
    super.key,
  });

  /// The `active` axis — which tab is current.
  final AppTab active;

  /// Tab tap handler (re-tapping the active tab is the consumer's
  /// pop-to-root concern, CV-7).
  final ValueChanged<AppTab> onSelect;

  /// The `badge` axis — none (`null`/0) or count on Orders (MI-16).
  final int? ordersBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: <Widget>[
              for (final tab in AppTab.values)
                Expanded(
                  child: _TabItem(
                    tab: tab,
                    active: tab == active,
                    badge: tab == AppTab.orders ? ordersBadge : null,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final AppTab tab;
  final bool active;
  final int? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;

    final Widget glyph;
    if (tab == AppTab.create) {
      // Figma master: 40px accent-gradient FAB, white plus, pink glow.
      glyph = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: colors.accentGradient,
          borderRadius: BorderRadius.circular(radii.pill),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.accentStart.withValues(alpha: 0.35),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(tab.icon, size: 20, color: colors.onAccent),
      );
    } else {
      glyph = Icon(
        tab.icon,
        size: 24,
        color: active ? colors.text : colors.text2,
      );
    }

    return Semantics(
      label: tab.semanticLabel,
      selected: active,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              glyph,
              if (badge != null && badge! > 0)
                Positioned(
                  // Figma master: badge rides the icon's top-right corner.
                  top: -10,
                  left: 17.5,
                  child: _Badge(count: badge!),
                ),
              if (active && tab != AppTab.create)
                Positioned(
                  // Figma master: 4px gradient dot 7px under the glyph.
                  bottom: -11,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: colors.accentGradient,
                      borderRadius: BorderRadius.circular(radii.pill),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.like,
        borderRadius: BorderRadius.circular(radii.pill),
      ),
      child: Text(
        formatCount(count),
        style: typography.micro12.copyWith(
          fontSize: 10,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: colors.onAccent,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
