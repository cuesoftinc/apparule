import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// CountdownRing (Figma 60:590) — `count` 3/2/1, both themes (the ring is
/// on-media white by design; the dark cell shows the shipping surface).
/// Rendered over a neutral block standing in for the camera feed.
void main() {
  themedGoldenTest(
    'CountdownRing matrix',
    fileName: 'countdown_ring',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: <Widget>[
        for (final count in CountdownCount.values)
          GoldenTestScenario(
            name: 'count ${count.value}',
            child: ColoredBox(
              color: const Color(0xFF333333),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CountdownRing(count: count),
              ),
            ),
          ),
      ],
    ),
  );
}
