import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/app_switch.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// Switch (Figma §8.2b form primitives) — on/off × enabled/disabled,
/// both themes; on paints the accent gradient track.
void main() {
  themedGoldenTest(
    'AppSwitch',
    fileName: 'app_switch',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'on',
          child: AppSwitch(value: true, onChanged: (_) {}),
        ),
        GoldenTestScenario(
          name: 'off',
          child: AppSwitch(value: false, onChanged: (_) {}),
        ),
        GoldenTestScenario(
          name: 'on · disabled',
          child: const AppSwitch(value: true, onChanged: null),
        ),
        GoldenTestScenario(
          name: 'off · disabled',
          child: const AppSwitch(value: false, onChanged: null),
        ),
      ],
    ),
  );
}
