import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers one [goldenTest] per theme — every module suite renders its
/// full variant×state matrix in light AND dark (mobile-implementation.md
/// §7: a component is not done until its goldens exist, both themes).
///
/// File names land as `goldens/ci/<fileName>_light.png` /
/// `..._dark.png`.
void themedGoldenTest(
  String description, {
  required String fileName,
  required ValueGetter<Widget> builder,
  BoxConstraints constraints = const BoxConstraints(),
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
  Interaction? whilePerforming,
}) {
  for (final (suffix, theme) in <(String, ThemeData)>[
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    AlchemistConfig.runWithConfig(
      config: AlchemistConfig.current().merge(AlchemistConfig(theme: theme)),
      // goldenTest registers the test synchronously; its Future completes
      // with registration, not the test run.
      run: () => unawaited(
        goldenTest(
          '$description ($suffix)',
          fileName: '${fileName}_$suffix',
          constraints: constraints,
          pumpBeforeTest: pumpBeforeTest,
          whilePerforming: whilePerforming,
          builder: builder,
        ),
      ),
    );
  }
}

/// Pump once and advance a fixed 50ms — the deterministic pump for
/// scenarios that host repeating animations (spinners, shimmer, pulses),
/// where [onlyPumpAndSettle] would never settle.
Future<void> pumpFrame(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 50));
}
