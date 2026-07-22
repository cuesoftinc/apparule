import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/notification_settings_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// B7 Notifications sub-screen (canvas 207:2) — the seven toggles in
/// their seeded states + the always-sent footer, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'NotificationSettingsScreen seeded',
    fileName: 'notification_settings_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'seeded toggle states',
          child: screenFrame(
            const NotificationSettingsScreen(),
            profileRepository: ProfileRepositoryFake(now: () => pinned),
          ),
        ),
      ],
    ),
  );
}
