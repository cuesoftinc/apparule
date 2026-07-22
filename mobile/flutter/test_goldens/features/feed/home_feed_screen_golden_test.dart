import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C2 — story rail over the PostCard column, both themes. One pinned
/// instant drives the seeded fake AND the screen clock, so relative
/// labels stay byte-stable.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'HomeFeedScreen seeded',
    fileName: 'home_feed_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'story rail + feed',
          child: screenFrame(
            const HomeFeedScreen(),
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
