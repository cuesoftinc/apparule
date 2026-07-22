// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C9 other — a family over the username; follow morphs route through
/// `FollowGraphController`, which invalidates this family.

@ProviderFor(PublicProfileViewModel)
final publicProfileViewModelProvider = PublicProfileViewModelFamily._();

/// C9 other — a family over the username; follow morphs route through
/// `FollowGraphController`, which invalidates this family.
final class PublicProfileViewModelProvider
    extends $AsyncNotifierProvider<PublicProfileViewModel, PublicProfileState> {
  /// C9 other — a family over the username; follow morphs route through
  /// `FollowGraphController`, which invalidates this family.
  PublicProfileViewModelProvider._({
    required PublicProfileViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'publicProfileViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$publicProfileViewModelHash();

  @override
  String toString() {
    return r'publicProfileViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PublicProfileViewModel create() => PublicProfileViewModel();

  @override
  bool operator ==(Object other) {
    return other is PublicProfileViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicProfileViewModelHash() =>
    r'ed218bc6bee3a7ace00bcace11e4ca5060b21347';

/// C9 other — a family over the username; follow morphs route through
/// `FollowGraphController`, which invalidates this family.

final class PublicProfileViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          PublicProfileViewModel,
          AsyncValue<PublicProfileState>,
          PublicProfileState,
          FutureOr<PublicProfileState>,
          String
        > {
  PublicProfileViewModelFamily._()
    : super(
        retry: null,
        name: r'publicProfileViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// C9 other — a family over the username; follow morphs route through
  /// `FollowGraphController`, which invalidates this family.

  PublicProfileViewModelProvider call(String username) =>
      PublicProfileViewModelProvider._(argument: username, from: this);

  @override
  String toString() => r'publicProfileViewModelProvider';
}

/// C9 other — a family over the username; follow morphs route through
/// `FollowGraphController`, which invalidates this family.

abstract class _$PublicProfileViewModel
    extends $AsyncNotifier<PublicProfileState> {
  late final _$args = ref.$arg as String;
  String get username => _$args;

  FutureOr<PublicProfileState> build(String username);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PublicProfileState>, PublicProfileState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PublicProfileState>, PublicProfileState>,
              AsyncValue<PublicProfileState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
