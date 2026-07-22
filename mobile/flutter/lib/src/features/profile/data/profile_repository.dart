import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_repository.g.dart';

/// Abstract account repository — the C9 own header, the C9 edit-profile
/// form, and the B7 settings surface (mobile-implementation.md §3).
abstract class ProfileRepository {
  /// The signed-in user's account, or null when signed out.
  Future<Profile?> me();

  /// Edit profile (C9): display name, bio, and the optional X-10 tier-1
  /// location ("used to recommend nearby designers"). Null leaves a
  /// field unchanged; [clearLocation] removes the location outright.
  Future<Profile> updateMe({
    String? displayName,
    String? bio,
    ProfileLocation? location,
    bool clearLocation = false,
  });

  /// B7 Notifications sub-screen — persists the per-event toggle set
  /// (MI-18 optimistic at the ViewModel; the PATCH /me analogue).
  Future<Profile> setNotificationPrefs(NotificationPrefs prefs);

  /// B7 Privacy & consent sub-screen — AI-processing + nearby toggles.
  Future<Profile> setPrivacyPrefs(PrivacyPrefs prefs);

  /// "Download my data" (B7 Account & data): the export bundle —
  /// account, measurement sessions, orders, saved looks, and consent
  /// records (the B4 rights links resolve here).
  Future<Map<String, Object?>> exportData();

  /// The delete-everything request (B7 Account & data danger ladder) —
  /// flips the account to deletion-pending; a 30-day grace period runs
  /// before removal (data-model.md §4).
  Future<Profile> requestDeletion();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => throw UnimplementedError(
  'profileRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
