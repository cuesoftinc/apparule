import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_feed_view_model.g.dart';

/// C2 placeholder ViewModel — watches the abstract post repository;
/// flavor overrides supply the fake.
@riverpod
class HomeFeedViewModel extends _$HomeFeedViewModel {
  @override
  Future<List<Post>> build() => ref.watch(postRepositoryProvider).homeFeed();
}
