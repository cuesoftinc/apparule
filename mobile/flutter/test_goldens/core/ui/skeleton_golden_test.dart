import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// Skeleton (Figma 54:464) — `kind` line/avatar/media/card, both themes.
/// The MI-19 shimmer repeats, so the suite pumps a fixed frame.
void main() {
  themedGoldenTest(
    'Skeleton matrix',
    fileName: 'skeleton',
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        for (final kind in SkeletonKind.values)
          GoldenTestScenario(
            name: kind.name,
            child: SizedBox(width: 280, child: Skeleton(kind: kind)),
          ),
      ],
    ),
  );
}
