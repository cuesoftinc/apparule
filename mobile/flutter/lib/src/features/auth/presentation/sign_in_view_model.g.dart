// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C1's ViewModel (1:1 with `SignInScreen`) — owns the CTA action state:
/// idle → loading → idle/error. Navigation is not its job: the router's
/// auth redirect reacts to the session provider once the repository
/// lands a session.

@ProviderFor(SignInViewModel)
final signInViewModelProvider = SignInViewModelProvider._();

/// C1's ViewModel (1:1 with `SignInScreen`) — owns the CTA action state:
/// idle → loading → idle/error. Navigation is not its job: the router's
/// auth redirect reacts to the session provider once the repository
/// lands a session.
final class SignInViewModelProvider
    extends $AsyncNotifierProvider<SignInViewModel, void> {
  /// C1's ViewModel (1:1 with `SignInScreen`) — owns the CTA action state:
  /// idle → loading → idle/error. Navigation is not its job: the router's
  /// auth redirect reacts to the session provider once the repository
  /// lands a session.
  SignInViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInViewModelHash();

  @$internal
  @override
  SignInViewModel create() => SignInViewModel();
}

String _$signInViewModelHash() => r'567f5cf11c447aabccd7117c988990b9c5cc1db7';

/// C1's ViewModel (1:1 with `SignInScreen`) — owns the CTA action state:
/// idle → loading → idle/error. Navigation is not its job: the router's
/// auth redirect reacts to the session provider once the repository
/// lands a session.

abstract class _$SignInViewModel extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
