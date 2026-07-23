import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/domain/story_rail_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_feed_view_model.g.dart';

/// What C2 renders: the followed-designer feed plus its story rail.
typedef HomeFeedState = ({List<Post> posts, List<StoryRailEntry> stories});

/// C2's ViewModel — feed + story rail off the post repository. Engagement
/// mutations (like/save/comment) route through the `EngagementActions`
/// façade, whose declared fan-out invalidates this provider (CLASS 1 —
/// `ref.invalidate` on engagement surfaces outside the façade is banned);
/// the screen's value-preserving body switch keeps the rendered list
/// through those rebuilds (CLASS 2).
@riverpod
class HomeFeedViewModel extends _$HomeFeedViewModel {
  @override
  Future<HomeFeedState> build() async {
    final repository = ref.watch(postRepositoryProvider);
    return (
      posts: await repository.homeFeed(),
      stories: await repository.storyRail(),
    );
  }

  /// MI-5 pull-to-refresh.
  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
  }

  /// MI-8: opening a story dims its ring for the session.
  Future<void> markStorySeen(String username) async {
    await ref.read(postRepositoryProvider).markStorySeen(username);
    if (state.value case final current?) {
      state = AsyncData((
        posts: current.posts,
        stories: <StoryRailEntry>[
          for (final story in current.stories)
            story.username == username ? story.copyWith(unseen: false) : story,
        ],
      ));
    }
  }
}
