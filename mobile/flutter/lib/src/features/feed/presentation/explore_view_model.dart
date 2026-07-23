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

// The C3 follow morph routes through `FollowGraphController`
// (follow_list_view_model.dart) — the ONE optimistic mutation path into
// the social graph (CLASS 1/2; D02 convergence). Its declared fan-out
// invalidates this family alongside C2's feed, so `viewer_follows` and
// the home feed re-derive without a restart. The interim
// `ExploreFollowController` (explore-family-only invalidation) is gone.
