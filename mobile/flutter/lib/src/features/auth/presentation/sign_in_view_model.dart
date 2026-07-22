import 'dart:async';

import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_view_model.g.dart';

/// C1's ViewModel (1:1 with `SignInScreen`) — owns the CTA action state:
/// idle → loading → idle/error. Navigation is not its job: the router's
/// auth redirect reacts to the session provider once the repository
/// lands a session.
@riverpod
class SignInViewModel extends _$SignInViewModel {
  @override
  FutureOr<void> build() {}

  /// The single auth CTA (X-1). A dismissed sheet resolves silently —
  /// screen unchanged (flows/auth.md §4); other failures surface as
  /// [AuthException] on the error state for the View to map to copy.
  Future<void> continueWithGoogle() async {
    if (state.isLoading) return;
    state = const AsyncLoading<void>();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncData<void>(null);
    } on AuthException catch (error, stackTrace) {
      if (error.code == AuthErrorCode.canceled) {
        state = const AsyncData<void>(null);
        return;
      }
      state = AsyncError<void>(error, stackTrace);
    }
  }
}
