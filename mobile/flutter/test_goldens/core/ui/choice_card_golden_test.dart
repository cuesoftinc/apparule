import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/choice_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/golden_themes.dart';

/// ChoiceCard (Figma choice-card/*, 548:2750/2759) — the create chooser's
/// card language: primary (1.5px accent border) / secondary, both themes.
void main() {
  themedGoldenTest(
    'ChoiceCard matrix',
    fileName: 'choice_card',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'primary (take-measurements — accent border)',
          child: SizedBox(
            width: 358,
            child: ChoiceCard(
              icon: LucideIcons.camera,
              title: 'Take measurements',
              subtitle: 'Two photos — about a minute',
              primary: true,
              onTap: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'secondary (post-outfit — border stroke)',
          child: SizedBox(
            width: 358,
            child: ChoiceCard(
              icon: LucideIcons.shirt,
              title: 'Post an outfit',
              subtitle: 'Become a designer to post',
              onTap: () {},
            ),
          ),
        ),
      ],
    ),
  );
}
