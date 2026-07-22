import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/gradient_refresh_spinner.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// GradientSpinnerIndicator (MI-5) — the gradient arc across the pull
/// ladder plus the in-flight spin (fixed frame), both themes.
void main() {
  themedGoldenTest(
    'GradientRefreshSpinner indicator',
    fileName: 'gradient_refresh_spinner',
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 4,
      children: <GoldenTestScenario>[
        for (final progress in <double>[0.35, 0.7, 1])
          GoldenTestScenario(
            name: 'pull ${(progress * 100).round()}%',
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: GradientSpinnerIndicator(progress: progress),
              ),
            ),
          ),
        GoldenTestScenario(
          name: 'refreshing (spin frame)',
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: GradientSpinnerIndicator(progress: 1, spinning: true),
            ),
          ),
        ),
      ],
    ),
  );
}
