import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/action_row.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// ActionRow (Figma 46:140) — `liked` f/t × `saved` f/t, both themes.
void main() {
  themedGoldenTest(
    'ActionRow matrix',
    fileName: 'action_row',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        for (final liked in <bool>[false, true])
          for (final saved in <bool>[false, true])
            GoldenTestScenario(
              name: 'liked $liked · saved $saved',
              child: SizedBox(
                width: 390,
                child: ActionRow(
                  liked: liked,
                  saved: saved,
                  likeCount: 128,
                  onToggleLike: () {},
                  onToggleSave: () {},
                ),
              ),
            ),
      ],
    ),
  );
}
