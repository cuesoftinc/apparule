import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_themes.dart';

/// Button (Figma 39:66) — every `kind` × `size` × `state` cell, both
/// themes (§7). The pressed state is a real interaction, captured with
/// alchemist's press() in its own pair of files.
void main() {
  themedGoldenTest(
    'Button matrix',
    fileName: 'button',
    // Loading cells host a spinner — a settle would never finish.
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 3,
      children: <Widget>[
        for (final kind in ButtonKind.values)
          for (final size in ButtonSize.values) ...<Widget>[
            GoldenTestScenario(
              name: '${kind.name} ${size.name} default',
              child: Button(
                label: 'Continue',
                kind: kind,
                size: size,
                onPressed: () {},
              ),
            ),
            GoldenTestScenario(
              name: '${kind.name} ${size.name} disabled',
              child: Button(
                label: 'Continue',
                kind: kind,
                size: size,
                onPressed: null,
              ),
            ),
            GoldenTestScenario(
              name: '${kind.name} ${size.name} loading',
              child: Button(
                label: 'Continue',
                kind: kind,
                size: size,
                loading: true,
                onPressed: () {},
              ),
            ),
          ],
      ],
    ),
  );

  themedGoldenTest(
    'Button pressed',
    fileName: 'button_pressed',
    whilePerforming: press(find.byType(Button)),
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        for (final kind in ButtonKind.values)
          for (final size in ButtonSize.values)
            GoldenTestScenario(
              name: '${kind.name} ${size.name} pressed',
              child: Button(
                label: 'Continue',
                kind: kind,
                size: size,
                onPressed: () {},
              ),
            ),
      ],
    ),
  );
}
