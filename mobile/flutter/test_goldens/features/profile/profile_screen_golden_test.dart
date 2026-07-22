import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/profile_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C9 own (canvas 174:964) — the vault-ring header, graph counts, the
/// liked grid under the icon tabs, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'ProfileScreen seeded',
    fileName: 'profile_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'own · liked grid',
          child: screenFrame(
            const ProfileScreen(),
            postRepository: PostRepositoryFake(now: () => pinned),
            profileRepository: ProfileRepositoryFake(now: () => pinned),
            measurementRepository: MeasurementRepositoryFake(
              now: () => pinned,
            ),
            earningsRepository: EarningsRepositoryFake(
              now: () => pinned,
              resolveDelay: Duration.zero,
            ),
            overrides: <Override>[
              clockProvider.overrideWith(
                (ref) =>
                    () => pinned,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
