// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The B7 settings ViewModel — one account snapshot shared by the root
/// screen and the three sub-screens. Toggles apply optimistically
/// (MI-18: flip the local snapshot, persist, roll back on failure) and
/// the deletion request re-derives every profile surface.

@ProviderFor(SettingsViewModel)
final settingsViewModelProvider = SettingsViewModelProvider._();

/// The B7 settings ViewModel — one account snapshot shared by the root
/// screen and the three sub-screens. Toggles apply optimistically
/// (MI-18: flip the local snapshot, persist, roll back on failure) and
/// the deletion request re-derives every profile surface.
final class SettingsViewModelProvider
    extends $AsyncNotifierProvider<SettingsViewModel, Profile?> {
  /// The B7 settings ViewModel — one account snapshot shared by the root
  /// screen and the three sub-screens. Toggles apply optimistically
  /// (MI-18: flip the local snapshot, persist, roll back on failure) and
  /// the deletion request re-derives every profile surface.
  SettingsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsViewModelHash();

  @$internal
  @override
  SettingsViewModel create() => SettingsViewModel();
}

String _$settingsViewModelHash() => r'16c0b597dcf923f4692aa529a2c2efb4c767bbe7';

/// The B7 settings ViewModel — one account snapshot shared by the root
/// screen and the three sub-screens. Toggles apply optimistically
/// (MI-18: flip the local snapshot, persist, roll back on failure) and
/// the deletion request re-derives every profile surface.

abstract class _$SettingsViewModel extends $AsyncNotifier<Profile?> {
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
