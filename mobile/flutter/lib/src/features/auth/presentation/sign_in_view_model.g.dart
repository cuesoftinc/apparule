// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C1 placeholder ViewModel — exercises the View → ViewModel →
/// repository layering end to end over the fake session restore.

@ProviderFor(SignInViewModel)
final signInViewModelProvider = SignInViewModelProvider._();

/// C1 placeholder ViewModel — exercises the View → ViewModel →
/// repository layering end to end over the fake session restore.
final class SignInViewModelProvider
    extends $AsyncNotifierProvider<SignInViewModel, AuthSession?> {
  /// C1 placeholder ViewModel — exercises the View → ViewModel →
  /// repository layering end to end over the fake session restore.
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

String _$signInViewModelHash() => r'05bc4d5abecf0a911570e08315731dd6eda73de6';

/// C1 placeholder ViewModel — exercises the View → ViewModel →
/// repository layering end to end over the fake session restore.

abstract class _$SignInViewModel extends $AsyncNotifier<AuthSession?> {
  FutureOr<AuthSession?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthSession?>, AuthSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthSession?>, AuthSession?>,
              AsyncValue<AuthSession?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
