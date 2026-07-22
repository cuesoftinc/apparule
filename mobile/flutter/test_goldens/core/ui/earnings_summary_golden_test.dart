import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/earnings_summary.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// EarningsSummary (Figma 97:1249, single component) — both themes;
/// 24px stats keep base success/warn (AA-large canon), tnum on.
void main() {
  themedGoldenTest(
    'EarningsSummary',
    fileName: 'earnings_summary',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'available + in escrow',
          child: const SizedBox(
            width: 390,
            child: EarningsSummary(
              balanceCents: 24300000,
              pendingCents: 4050000,
            ),
          ),
        ),
      ],
    ),
  );
}
