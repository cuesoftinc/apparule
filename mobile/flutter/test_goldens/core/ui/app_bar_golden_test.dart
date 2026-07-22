import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/golden_themes.dart';

/// AppBar (Figma 85:994) — `kind` root/sub/over-media, both themes.
void main() {
  themedGoldenTest(
    'AppTopBar matrix',
    fileName: 'app_bar',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'root — gradient wordmark + trailing slot',
          child: const SizedBox(
            width: 390,
            child: AppTopBar(
              title: 'Apparule',
              trailing: Icon(LucideIcons.bell, size: 24),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'sub — back + centred title + trailing',
          child: SizedBox(
            width: 390,
            child: AppTopBar(
              kind: AppTopBarKind.sub,
              title: 'Order #A2041',
              onBack: () {},
              trailing: const Icon(LucideIcons.ellipsis, size: 24),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'over-media — scrim + on-media white',
          child: SizedBox(
            width: 390,
            child: ColoredBox(
              color: const Color(0xFF444444),
              child: AppTopBar(
                kind: AppTopBarKind.overMedia,
                title: 'Post',
                onBack: () {},
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
