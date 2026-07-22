import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_detail_view_model.g.dart';

/// C4's ViewModel — one post; like/save mutate the repository and echo
/// back into this state AND every other engagement surface (C2 feed,
/// C9 liked/saved grids — the surfaces render the same fake truth).
@riverpod
class PostDetailViewModel extends _$PostDetailViewModel {
  @override
  Future<Post> build(String postId) =>
      ref.watch(postRepositoryProvider).post(postId);

  Future<void> toggleLike() async {
    final updated = await ref.read(postRepositoryProvider).toggleLike(postId);
    state = AsyncData(updated);
    ref
      ..invalidate(homeFeedViewModelProvider)
      ..invalidate(profileViewModelProvider);
  }

  Future<void> toggleSave() async {
    final updated = await ref.read(postRepositoryProvider).toggleSave(postId);
    state = AsyncData(updated);
    ref
      ..invalidate(homeFeedViewModelProvider)
      ..invalidate(profileViewModelProvider);
  }
}
