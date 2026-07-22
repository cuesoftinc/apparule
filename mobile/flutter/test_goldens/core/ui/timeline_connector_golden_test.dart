import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/timeline_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_themes.dart';

/// TimelineConnector (MI-14) — the dot ladder (done / current / upcoming /
/// terminal error) with fully drawn connectors, both themes. Pumps a
/// fixed 400ms so the draw completes and the current pulse sits at a
/// deterministic frame.
void main() {
  themedGoldenTest(
    'TimelineConnector',
    fileName: 'timeline_connector',
    pumpBeforeTest: (tester) =>
        tester.pump(const Duration(milliseconds: 400)),
    builder: () => GoldenTestGroup(
      columns: 4,
      children: <GoldenTestScenario>[
        for (final state in TimelineDotState.values)
          GoldenTestScenario(
            name: state.name,
            child: SizedBox(
              width: 40,
              height: 72,
              child: TimelineConnector(
                state: state,
                last: state == TimelineDotState.terminalError,
              ),
            ),
          ),
      ],
    ),
  );
}
