import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:apparule/l10n/generated/app_localizations.dart';
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
          // The app's l10n scope rides every component pump — catalog-
          // driven modules (UserRow's Follow/Following) resolve their
          // copy the way every screen host provides it. Renders nothing:
          // pixel-neutral for the committed CI goldens.
          builder: () => Localizations(
            locale: const Locale('en'),
            delegates: AppLocalizations.localizationsDelegates,
            child: builder(),
          ),
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

/// Settles the scenario BEFORE precaching — for seeded SCREEN goldens
/// whose ViewModels load asynchronously: the Image widgets only exist
/// once the data state renders, so a bare [precacheThenFrame] would scan
/// the loading skeleton and cache nothing.
Future<void> settleThenPrecache(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await precacheThenFrame(tester);
}

/// Alchemist's [precacheImages] with a bounded final pump instead of its
/// trailing `pumpAndSettle` — for image-bearing scenarios that also host
/// repeating animations (PostCard shimmer siblings, the processing
/// pulse), where a settle never finishes.
Future<void> precacheThenFrame(WidgetTester tester) async {
  await tester.runAsync(() async {
    final images = <Future<void>>[];
    for (final element in find.byType(Image).evaluate()) {
      images.add(precacheImage((element.widget as Image).image, element));
    }
    for (final element in find.byType(DecoratedBox).evaluate()) {
      final decoration = (element.widget as DecoratedBox).decoration;
      if (decoration is BoxDecoration && decoration.image != null) {
        images.add(precacheImage(decoration.image!.image, element));
      }
    }
    await Future.wait(images);
  });
  await pumpFrame(tester);
}
