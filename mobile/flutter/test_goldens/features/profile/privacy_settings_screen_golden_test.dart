import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/privacy_settings_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// B7 Privacy & consent sub-screen (canvas 207:7155) — toggles,
/// retention notice, the pinned-clock consent ledger, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'PrivacySettingsScreen seeded',
    fileName: 'privacy_settings_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'consents on, ledger seeded',
          child: screenFrame(
            const PrivacySettingsScreen(),
            profileRepository: ProfileRepositoryFake(now: () => pinned),
          ),
        ),
      ],
    ),
  );
}
