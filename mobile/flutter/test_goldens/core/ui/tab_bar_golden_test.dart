import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/tab_bar.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// TabBar (Figma 49:384) — `active` ×5 · `badge` none/count, both themes.
void main() {
  themedGoldenTest(
    'AppTabBar matrix',
    fileName: 'tab_bar',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        for (final tab in AppTab.values)
          GoldenTestScenario(
            name: 'active ${tab.name} · badge none',
            child: SizedBox(
              width: 390,
              child: AppTabBar(active: tab, onSelect: (_) {}),
            ),
          ),
        GoldenTestScenario(
          name: 'active home · badge count (MI-16)',
          child: SizedBox(
            width: 390,
            child: AppTabBar(
              active: AppTab.home,
              ordersBadge: 3,
              onSelect: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'active orders · badge count 2 digits',
          child: SizedBox(
            width: 390,
            child: AppTabBar(
              active: AppTab.orders,
              ordersBadge: 12,
              onSelect: (_) {},
            ),
          ),
        ),
      ],
    ),
  );
}
