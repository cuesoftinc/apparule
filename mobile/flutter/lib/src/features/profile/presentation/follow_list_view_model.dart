import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/user_summary.dart';
import 'package:apparule/src/features/feed/presentation/explore_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'follow_list_view_model.g.dart';

/// Which C12 tab a list derivation serves.
enum FollowListKind { followers, following }

/// C12's list derivation — one family instance per (username, tab); the
/// controller below invalidates the whole family after a morph so both
/// tabs re-derive from the mutated graph.
@riverpod
Future<List<UserSummary>> followList(
  Ref ref, {
  required String username,
  required FollowListKind kind,
}) {
  final repository = ref.watch(postRepositoryProvider);
  return switch (kind) {
    FollowListKind.followers => repository.followersOf(username),
    FollowListKind.following => repository.followingOf(username),
  };
}

/// The profile-surface MI-7 morph (C9 public header + C12 rows) — one
/// mutation path into the social graph, then every derivation that
/// renders follow state re-derives: the C12 lists, the C9 headers (own
/// counts + public morph), and C3's sections (ViewModel-to-ViewModel
/// invalidation is the ratified orchestration idiom — the repository
/// stays the single source of truth). keepAlive for the same reason as
/// ExploreFollowController: read-only orchestration must not unmount its
/// Ref across the repository await.
@Riverpod(keepAlive: true)
class FollowGraphController extends _$FollowGraphController {
  @override
  void build() {}

  Future<void> setFollow(String username, {required bool follow}) async {
    await ref.read(postRepositoryProvider).setFollow(username, follow: follow);
    ref
      ..invalidate(followListProvider)
      ..invalidate(publicProfileViewModelProvider)
      ..invalidate(profileViewModelProvider)
      ..invalidate(exploreViewModelProvider);
  }
}
