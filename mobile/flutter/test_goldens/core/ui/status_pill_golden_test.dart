import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// StatusPill (Figma 47:135) — all 13 `status` cells (10 order states +
/// the freshness ladder), both themes. Labels bind the AA `-text`
/// variants per the [Decided 2026-07-16] mapping.
void main() {
  themedGoldenTest(
    'StatusPill matrix',
    fileName: 'status_pill',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: <Widget>[
        for (final status in StatusPillValue.values)
          GoldenTestScenario(
            name: status.name,
            child: StatusPill(status: status),
          ),
      ],
    ),
  );
}
