// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C9 placeholder ViewModel — watches the abstract profile repository;
/// flavor overrides supply the fake.

@ProviderFor(ProfileViewModel)
final profileViewModelProvider = ProfileViewModelProvider._();

/// C9 placeholder ViewModel — watches the abstract profile repository;
/// flavor overrides supply the fake.
final class ProfileViewModelProvider
    extends $AsyncNotifierProvider<ProfileViewModel, Profile?> {
  /// C9 placeholder ViewModel — watches the abstract profile repository;
  /// flavor overrides supply the fake.
  ProfileViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileViewModelHash();

  @$internal
  @override
  ProfileViewModel create() => ProfileViewModel();
}

String _$profileViewModelHash() => r'27ccbdbea9ea92f2372d8e8595da2627b34d2e42';

/// C9 placeholder ViewModel — watches the abstract profile repository;
/// flavor overrides supply the fake.

abstract class _$ProfileViewModel extends $AsyncNotifier<Profile?> {
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
