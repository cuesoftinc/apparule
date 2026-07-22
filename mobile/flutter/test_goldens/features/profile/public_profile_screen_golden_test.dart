import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C9 other (canvas 267:8539) — amara's B6 header off the graph, the
/// Following/Request pair, the published grid, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'PublicProfileScreen seeded',
    fileName: 'public_profile_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'designer (amara.designs)',
          child: screenFrame(
            const PublicProfileScreen(username: 'amara.designs'),
            postRepository: PostRepositoryFake(now: () => pinned),
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
