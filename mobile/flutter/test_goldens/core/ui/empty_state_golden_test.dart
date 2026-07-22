import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// EmptyState (Figma 54:459) — `kind` ×6 with canonical copy/CTA kinds,
/// both themes.
void main() {
  themedGoldenTest(
    'EmptyState matrix',
    fileName: 'empty_state',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        for (final kind in EmptyStateKind.values)
          GoldenTestScenario(
            name: kind.name,
            child: SizedBox(width: 340, child: EmptyState(kind: kind)),
          ),
      ],
    ),
  );
}
