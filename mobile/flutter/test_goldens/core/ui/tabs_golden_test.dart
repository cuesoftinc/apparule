import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/tabs.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/golden_themes.dart';

/// Tabs (Figma chrome kit) — `kind: text / icon` × `active: first /
/// second`, both themes.
void main() {
  themedGoldenTest(
    'AppTabs',
    fileName: 'tabs',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'text · first active',
          child: SizedBox(
            width: 390,
            child: AppTabs(
              first: const AppTabItem.text('4.2k followers'),
              second: const AppTabItem.text('310 following'),
              active: AppTabsActive.first,
              onSelect: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'text · second active',
          child: SizedBox(
            width: 390,
            child: AppTabs(
              first: const AppTabItem.text('4.2k followers'),
              second: const AppTabItem.text('310 following'),
              active: AppTabsActive.second,
              onSelect: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'icon · first active',
          child: SizedBox(
            width: 390,
            child: AppTabs(
              first: const AppTabItem.icon(
                LucideIcons.grid3X3,
                semanticLabel: 'Posts',
              ),
              second: const AppTabItem.icon(
                LucideIcons.bookmark,
                semanticLabel: 'Saved looks',
              ),
              active: AppTabsActive.first,
              onSelect: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'icon · second active',
          child: SizedBox(
            width: 390,
            child: AppTabs(
              first: const AppTabItem.icon(
                LucideIcons.grid3X3,
                semanticLabel: 'Posts',
              ),
              second: const AppTabItem.icon(
                LucideIcons.bookmark,
                semanticLabel: 'Saved looks',
              ),
              active: AppTabsActive.second,
              onSelect: (_) {},
            ),
          ),
        ),
      ],
    ),
  );
}
