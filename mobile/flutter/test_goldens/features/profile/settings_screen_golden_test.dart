import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// B7 settings root — identity, creator row, appearance tri-state,
/// sub-screen rows, legal links, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);
  // The theme controller hydrates through the persistence seam.
  SharedPreferences.setMockInitialValues(<String, Object>{});

  themedGoldenTest(
    'SettingsScreen seeded',
    fileName: 'settings_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'root (non-designer)',
          child: screenFrame(
            const SettingsScreen(),
            profileRepository: ProfileRepositoryFake(now: () => pinned),
            earningsRepository: EarningsRepositoryFake(
              now: () => pinned,
              resolveDelay: Duration.zero,
            ),
          ),
        ),
      ],
    ),
  );
}
