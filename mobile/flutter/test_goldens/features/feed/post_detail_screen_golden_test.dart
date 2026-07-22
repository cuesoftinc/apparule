import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/post_detail_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C4 — sub bar · PostCard anatomy · composer affordance · pinned
/// Request CTA, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'PostDetailScreen seeded',
    fileName: 'post_detail_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'agbada post',
          child: screenFrame(
            const PostDetailScreen(postId: 'post-agbada'),
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
