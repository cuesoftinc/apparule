import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_screen.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_view_model.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C12 (canvas 205:7203) — amara's followers under the count tabs:
/// UserRows with the MI-7 morph on designer rows, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'FollowListScreen seeded',
    fileName: 'follow_list_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'followers of amara.designs',
          child: screenFrame(
            const FollowListScreen(
              username: 'amara.designs',
              initialKind: FollowListKind.followers,
            ),
            postRepository: PostRepositoryFake(now: () => pinned),
          ),
        ),
      ],
    ),
  );
}
