import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_view_model.freezed.dart';
part 'profile_view_model.g.dart';

/// The C9 own-profile view state — identity from the account repository,
/// counts from the social graph, grids from the post projections, the
/// MI-11 vault-freshness ring from the newest session, and the
/// designer-side flag from the earnings repository (each repository
/// stays the single source of truth for its domain; the ViewModel is
/// the composition point — mobile-implementation.md §3/§4).
@freezed
abstract class OwnProfileState with _$OwnProfileState {
  const factory OwnProfileState({
    required Profile profile,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int postsCount,
    @Default(false) bool designerEnabled,

    /// MI-11 ladder value (`fresh`/`aging`/`stale`), or null with an
    /// empty vault — the ring is the C7 entry affordance either way.
    String? vaultFreshness,

    /// Days since the newest vault session — the MI-11 tooltip's
    /// "Measured N days ago — retake?" value (null with an empty vault).
    int? vaultMeasuredDaysAgo,

    /// First grid tab: the designer side's published posts; a regular
    /// user's liked grid (pages.md C9 "grid of liked/saved").
    @Default(<Post>[]) List<Post> gridPosts,

    /// Second tab: saved looks — viewer-private by construction.
    @Default(<Post>[]) List<Post> savedPosts,
  }) = _OwnProfileState;
}

/// C9 own — null when signed out (the router redirect owns that case).
@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  @override
  Future<OwnProfileState?> build() async {
    final profile = await ref.watch(profileRepositoryProvider).me();
    if (profile == null) return null;
    final posts = ref.watch(postRepositoryProvider);
    final status = await ref.watch(earningsRepositoryProvider).status();
    final followers = await posts.followersOf(profile.username);
    final following = await posts.followingOf(profile.username);
    final gridPosts = status.enabled
        ? await posts.postsBy(profile.username)
        : await posts.likedPosts();
    final saved = await posts.savedPosts();
    final sessions = await ref
        .watch(measurementRepositoryProvider)
        .vaultSessions();

    String? freshness;
    int? measuredDaysAgo;
    if (sessions.isNotEmpty) {
      final newest = sessions
          .map((session) => session.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final days = ref.watch(clockProvider)().difference(newest).inDays;
      measuredDaysAgo = days;
      freshness = days < 30
          ? 'fresh'
          : days < 90
          ? 'aging'
          : 'stale';
    }

    return OwnProfileState(
      profile: profile,
      followersCount: followers.length,
      followingCount: following.length,
      postsCount: status.enabled ? gridPosts.length : 0,
      designerEnabled: status.enabled,
      vaultFreshness: freshness,
      vaultMeasuredDaysAgo: measuredDaysAgo,
      gridPosts: gridPosts,
      savedPosts: saved,
    );
  }
}
