// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The C9 edit-profile ViewModel — loads the current account for the
/// form's initial values; [save] persists and re-derives the C9 header.

@ProviderFor(EditProfileViewModel)
final editProfileViewModelProvider = EditProfileViewModelProvider._();

/// The C9 edit-profile ViewModel — loads the current account for the
/// form's initial values; [save] persists and re-derives the C9 header.
final class EditProfileViewModelProvider
    extends $AsyncNotifierProvider<EditProfileViewModel, Profile?> {
  /// The C9 edit-profile ViewModel — loads the current account for the
  /// form's initial values; [save] persists and re-derives the C9 header.
  EditProfileViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editProfileViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editProfileViewModelHash();

  @$internal
  @override
  EditProfileViewModel create() => EditProfileViewModel();
}

String _$editProfileViewModelHash() =>
    r'109253189d2ba8e4d00111d2557a1abe552a4e5a';

/// The C9 edit-profile ViewModel — loads the current account for the
/// form's initial values; [save] persists and re-derives the C9 header.

abstract class _$EditProfileViewModel extends $AsyncNotifier<Profile?> {
  FutureOr<Profile?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Profile?>, Profile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Profile?>, Profile?>,
              AsyncValue<Profile?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
