import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/presentation/designer_onboarding_screen.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C13 intro (canvas 204:1140) — headline, bullets, the prefilled
/// create form, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'DesignerOnboardingScreen seeded',
    fileName: 'designer_onboarding_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'intro + create form',
          child: screenFrame(
            const DesignerOnboardingScreen(),
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
