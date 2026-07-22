import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/explore_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C3 — search field + chips over the 3-col browse grid, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'ExploreScreen seeded',
    fileName: 'explore_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'browse grid',
          child: screenFrame(
            const ExploreScreen(),
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
