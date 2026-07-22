import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/feed/domain/public_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'public_profile_view_model.freezed.dart';
part 'public_profile_view_model.g.dart';

/// The C9 `/profile/{username}` view state — the B6 header block plus
/// the designer's published grid (regular users carry no grid: saved is
/// viewer-private and vaults are never public).
@freezed
abstract class PublicProfileState with _$PublicProfileState {
  const factory PublicProfileState({
    required PublicProfile profile,
    @Default(<Post>[]) List<Post> posts,
  }) = _PublicProfileState;
}

/// C9 other — a family over the username; follow morphs route through
/// `FollowGraphController`, which invalidates this family.
@riverpod
class PublicProfileViewModel extends _$PublicProfileViewModel {
  @override
  Future<PublicProfileState> build(String username) async {
    final repository = ref.watch(postRepositoryProvider);
    final profile = await repository.publicProfile(username);
    return PublicProfileState(
      profile: profile,
      posts: profile.isDesigner
          ? await repository.postsBy(username)
          : const <Post>[],
    );
  }
}
