import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/caught_up_divider.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// CaughtUpDivider (Figma 96:1214, single component) — both themes.
void main() {
  themedGoldenTest(
    'CaughtUpDivider',
    fileName: 'caught_up_divider',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'single (MI-6)',
          child: const SizedBox(width: 390, child: CaughtUpDivider()),
        ),
      ],
    ),
  );
}
