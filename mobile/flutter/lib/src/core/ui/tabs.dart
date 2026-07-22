import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The Figma `Tabs` set's `active` axis — which of the two items is
/// selected (the as-built 2026-07-17 property shape: `active: first /
/// second`, not a per-item state axis).
enum AppTabsActive {
  /// The leading item is selected.
  first,

  /// The trailing item is selected.
  second,
}

/// One tab cell — a text label (`kind: text`) or an icon (`kind: icon`).
/// The optional [semanticLabel] names icon cells for assistive tech
/// (text cells read their own label).
class AppTabItem {
  const AppTabItem.text(String this.label) : icon = null, semanticLabel = null;

  const AppTabItem.icon(IconData this.icon, {required this.semanticLabel})
    : label = null;

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
}

/// Tabs — the Figma `Tabs` set (§8.2b chrome kit); web sibling
/// `Tabs.tsx`. Axes: `kind: text / icon` (both cells carry the same
/// kind by construction) × `active: first / second`, with the underline
/// indicator: the active cell draws a 2px text-token bottom border over
/// the row's 1px hairline (the C8 role-tab idiom). Consumed by C9
/// (icon: grid · saved) and C12 (text: followers · following).
class AppTabs extends StatelessWidget {
  const AppTabs({
    required this.first,
    required this.second,
    required this.active,
    required this.onSelect,
    super.key,
  });

  final AppTabItem first;
  final AppTabItem second;
  final AppTabsActive active;
  final ValueChanged<AppTabsActive> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _TabCell(
          item: first,
          active: active == AppTabsActive.first,
          onTap: () => onSelect(AppTabsActive.first),
        ),
        _TabCell(
          item: second,
          active: active == AppTabsActive.second,
          onTap: () => onSelect(AppTabsActive.second),
        ),
      ],
    );
  }
}

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final AppTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final color = active ? colors.text : colors.text2;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: item.semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? colors.text : colors.border,
                  width: active ? 2 : 1,
                ),
              ),
            ),
            child: item.icon != null
                ? Icon(item.icon, size: 22, color: color)
                : Text(
                    item.label!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body14.copyWith(
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
