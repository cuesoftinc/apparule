import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_profile_view_model.g.dart';

/// The C9 edit-profile ViewModel — loads the current account for the
/// form's initial values; [save] persists and re-derives the C9 header.
@riverpod
class EditProfileViewModel extends _$EditProfileViewModel {
  @override
  Future<Profile?> build() => ref.watch(profileRepositoryProvider).me();

  Future<void> save({
    required String displayName,
    required String bio,
    required String city,
    required String state,
  }) async {
    // D54: an empty display name never persists — the C9 header would
    // render a blank identity line (web "Display name is required"
    // parity; the screen disarms Save, this guards the API).
    if (displayName.trim().isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Display name is required',
      );
    }
    final repository = ref.read(profileRepositoryProvider);
    final trimmedCity = city.trim();
    final trimmedState = state.trim();
    await repository.updateMe(
      displayName: displayName.trim(),
      bio: bio.trim(),
      // X-10 tier 1: location stays optional — clearing both fields
      // removes it (country pins NG, the v1 market).
      location: trimmedCity.isEmpty && trimmedState.isEmpty
          ? null
          : ProfileLocation(
              city: trimmedCity,
              state: trimmedState.isEmpty ? trimmedCity : trimmedState,
              country: 'NG',
            ),
      clearLocation: trimmedCity.isEmpty && trimmedState.isEmpty,
    );
    ref.invalidate(profileViewModelProvider);
  }
}
