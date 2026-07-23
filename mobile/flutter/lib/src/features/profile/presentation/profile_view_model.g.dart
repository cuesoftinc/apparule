// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C9 own — null when signed out (the router redirect owns that case).

@ProviderFor(ProfileViewModel)
final profileViewModelProvider = ProfileViewModelProvider._();

/// C9 own — null when signed out (the router redirect owns that case).
final class ProfileViewModelProvider
    extends $AsyncNotifierProvider<ProfileViewModel, OwnProfileState?> {
  /// C9 own — null when signed out (the router redirect owns that case).
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

String _$profileViewModelHash() => r'608a71fe4a3eb196b7f177ed19dd523224ec3fea';

/// C9 own — null when signed out (the router redirect owns that case).

abstract class _$ProfileViewModel extends $AsyncNotifier<OwnProfileState?> {
  FutureOr<OwnProfileState?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OwnProfileState?>, OwnProfileState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OwnProfileState?>, OwnProfileState?>,
              AsyncValue<OwnProfileState?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
