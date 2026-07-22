import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C6 guide (M-8/M-10 canvas-first rebuild, 529:2441) — the intro step
/// through the one parameterized GuidePage, both themes; the per-step
/// illustration matrix lives in the GuidePage component suite.
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
