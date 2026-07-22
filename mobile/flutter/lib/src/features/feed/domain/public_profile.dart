import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_profile.freezed.dart';

/// A viewable profile (C9 `/profile/{username}`) — designer profiles
/// carry the B6 header block (bio, counts, MI-7 state); regular users
/// render the private-vault variant (pages.md B6: measurements are NEVER
/// public). Counts derive from the social graph — the web store's P1
/// realism invariant: header and follower sheet never disagree.
@freezed
abstract class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    required String username,
    required String displayName,
    String? avatarUrl,
    String? bio,
    String? locality,
    @Default(false) bool isDesigner,
    @Default(false) bool verified,
    @Default(0) int postsCount,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(false) bool viewerFollows,
    @Default(false) bool viewerIsSelf,
  }) = _PublicProfile;
}
