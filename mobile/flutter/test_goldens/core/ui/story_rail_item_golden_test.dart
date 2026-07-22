import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/story_rail_item.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// StoryRailItem (Figma 46:95) — `state` unseen/seen/loading, both
/// themes. The loading ring rotates (MI-8), so the suite pumps a fixed
/// frame instead of settling.
void main() {
  themedGoldenTest(
    'StoryRailItem matrix',
    fileName: 'story_rail_item',
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 3,
      children: <Widget>[
        for (final state in StoryRailItemState.values)
          GoldenTestScenario(
            name: state.name,
            child: StoryRailItem(
              username: 'eniola.stitches',
              state: state,
            ),
          ),
      ],
    ),
  );
}
