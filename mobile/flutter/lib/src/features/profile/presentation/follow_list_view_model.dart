import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/user_summary.dart';
import 'package:apparule/src/features/feed/presentation/explore_view_model.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_view_model.dart';
import 'package:apparule/src/features/profile/presentation/notifications_view_model.dart';
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

/// The MI-7 follow morph façade — optimistic by construction (the
/// interaction audit's CLASS 1 + CLASS 2 locks): ONE mutation path into
/// the social graph, and `ref.invalidate` on follow surfaces outside
/// this façade is banned.
///
/// State is the viewer's local follow OVERLAY (`username → follows`):
/// [setFollow] flips it SYNCHRONOUSLY — watching rows morph this frame,
/// never after a round-trip (D18/D19/D58) — then reconciles with the
/// repository. Failure rolls the overlay back and rethrows so callers
/// toast via `runAction`. Surfaces render
/// `overlay[username] ?? serverValue`.
///
/// DECLARED invalidation fan-out — follow/unfollow ⇒
///   · [followListProvider] (C12 lists, whole family),
///   · [publicProfileViewModelProvider] (C9 public headers),
///   · [profileViewModelProvider] (C9 own counts),
///   · [exploreViewModelProvider] (C3 sections),
///   · [viewerFollowingSetProvider] (C10 rows),
///   · [homeFeedViewModelProvider] (D02: the mounted Home branch must
///     re-derive — new follows' posts/rings appear without a restart).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// keepAlive: the overlay is session truth and the Ref must not unmount
/// across the repository await.
@Riverpod(keepAlive: true)
class FollowGraphController extends _$FollowGraphController {
  @override
  Map<String, bool> build() => const <String, bool>{};

  Future<void> setFollow(String username, {required bool follow}) async {
    final previous = state;
    // Optimistic-by-construction: the local graph flips before the
    // repository answers (MI-18 — never a blocking spinner on a social
    // action).
    state = <String, bool>{...state, username: follow};
    try {
      await ref
          .read(postRepositoryProvider)
          .setFollow(username, follow: follow);
    } on Object {
      // Rollback + rethrow: the caller's runAction owns the toast.
      state = previous;
      rethrow;
    }
    ref
      ..invalidate(followListProvider)
      ..invalidate(publicProfileViewModelProvider)
      ..invalidate(profileViewModelProvider)
      ..invalidate(exploreViewModelProvider)
      ..invalidate(viewerFollowingSetProvider)
      ..invalidate(homeFeedViewModelProvider);
  }
}
