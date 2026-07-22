import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/domain/story_rail_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_feed_view_model.g.dart';

/// What C2 renders: the followed-designer feed plus its story rail.
typedef HomeFeedState = ({List<Post> posts, List<StoryRailEntry> stories});

/// C2's ViewModel — feed + story rail off the post repository; like/save
/// and story-seen calls are repository mutations echoed back into state
/// (MI-1/2/3/8 over real fake-state changes).
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

  Future<void> toggleLike(String postId) async {
    final updated = await ref.read(postRepositoryProvider).toggleLike(postId);
    _replacePost(updated);
  }

  Future<void> toggleSave(String postId) async {
    final updated = await ref.read(postRepositoryProvider).toggleSave(postId);
    _replacePost(updated);
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

  void _replacePost(Post updated) {
    if (state.value case final current?) {
      state = AsyncData((
        posts: <Post>[
          for (final post in current.posts)
            post.id == updated.id ? updated : post,
        ],
        stories: current.stories,
      ));
    }
  }
}
