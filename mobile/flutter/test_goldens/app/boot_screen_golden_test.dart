import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/app/boot_screen.dart';

import '../helpers/golden_themes.dart';
import '../helpers/screen_frame.dart';

/// The in-app boot frame (boot-flow directive 2026-07-22): gradient
/// wordmark centered on the token background — splash→C1 brand
/// continuity; the spinner only exists past ~300ms of pending restore
/// (the second scenario pumps past the threshold).
void main() {
  themedGoldenTest(
    'BootScreen',
    fileName: 'boot_screen',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'restoring — wordmark only, no spinner',
          child: screenFrame(const BootScreen()),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'BootScreen waiting',
    fileName: 'boot_screen_waiting',
    // Past kBootSpinnerDelay with a pending restore: bounded pumps at a
    // fixed offset — the spinner repeats forever, so a settle never ends.
    pumpBeforeTest: (tester) async {
      await tester.pump(kBootSpinnerDelay + const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    },
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'restore past ~300ms — quiet spinner',
          child: screenFrame(const BootScreen()),
        ),
      ],
    ),
  );
}
