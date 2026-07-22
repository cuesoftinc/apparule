import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C6 guide (§10/§11 salvage) — the first single-pose step through the
/// one parameterized page widget, both themes.
void main() {
  // The guide watches the persisted first-completion flag; goldens run
  // outside test/, so the analyzer can't see this is still a test.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(<String, Object>{});

  themedGoldenTest(
    'CaptureGuideScreen first step',
    fileName: 'guide_screen',
    pumpBeforeTest: precacheThenFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'step 1 — Guide A-Z',
          child: screenFrame(const CaptureGuideScreen()),
        ),
      ],
    ),
  );
}
