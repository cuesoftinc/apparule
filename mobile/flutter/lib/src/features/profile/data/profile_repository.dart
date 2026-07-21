import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_repository.g.dart';

/// Abstract profile repository — C9/C10/C12 (mobile-implementation.md §3).
abstract class ProfileRepository {
  /// The signed-in user's profile, or null when signed out.
  Future<Profile?> me();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => throw UnimplementedError(
  'profileRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
