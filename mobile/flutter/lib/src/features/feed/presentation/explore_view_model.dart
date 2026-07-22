import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/explore_results.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'explore_view_model.g.dart';

/// C3's ViewModel — a family over the search/filter tuple (the screen
/// owns the controls; each combination is one derivation off the post
/// repository, so mutations elsewhere re-rank honestly on invalidate).
@riverpod
Future<ExploreResults> exploreViewModel(
  Ref ref, {
  String query = '',
  String? tag,
  bool nearMe = true,
}) => ref
    .watch(postRepositoryProvider)
    .explore(query: query, tag: tag, nearMe: nearMe);

/// MI-7 follow morph from the C3 designers section — mutates the graph,
/// then invalidates every explore derivation so `viewer_follows` (and
/// the C2 feed on its next build) re-derive. keepAlive: the controller
/// is read-only orchestration (no watched state), so autoDispose would
/// unmount its Ref across the repository await.
@Riverpod(keepAlive: true)
class ExploreFollowController extends _$ExploreFollowController {
  @override
  void build() {}

  Future<void> setFollow(String username, {required bool follow}) async {
    await ref.read(postRepositoryProvider).setFollow(username, follow: follow);
    ref.invalidate(exploreViewModelProvider);
  }
}
