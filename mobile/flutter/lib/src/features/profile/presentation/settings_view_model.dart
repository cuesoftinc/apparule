import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_view_model.g.dart';

/// The B7 settings ViewModel — one account snapshot shared by the root
/// screen and the three sub-screens. Toggles apply optimistically
/// (MI-18: flip the local snapshot, persist, roll back on failure) and
/// the deletion request re-derives every profile surface.
@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  @override
  Future<Profile?> build() => ref.watch(profileRepositoryProvider).me();

  Future<void> setNotificationPrefs(NotificationPrefs prefs) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(notificationPrefs: prefs));
    try {
      state = AsyncData(
        await ref
            .read(profileRepositoryProvider)
            .setNotificationPrefs(prefs),
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setPrivacyPrefs(PrivacyPrefs prefs) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(privacyPrefs: prefs));
    try {
      state = AsyncData(
        await ref.read(profileRepositoryProvider).setPrivacyPrefs(prefs),
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  /// "Download my data" — the export bundle (the screen confirms with
  /// the email-a-link copy per the canvas).
  Future<Map<String, Object?>> exportData() =>
      ref.read(profileRepositoryProvider).exportData();

  /// The armed rung of the danger ladder — only the typed-confirm sheet
  /// calls this.
  Future<void> requestDeletion() async {
    state = AsyncData(
      await ref.read(profileRepositoryProvider).requestDeletion(),
    );
    ref.invalidate(profileViewModelProvider);
  }

  /// B7 Account & data "Log out" — the router redirect owns navigation
  /// (authSession refresh sends every route to C1).
  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}
