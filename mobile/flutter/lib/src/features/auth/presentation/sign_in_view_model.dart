import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_view_model.g.dart';

/// C1 placeholder ViewModel — exercises the View → ViewModel →
/// repository layering end to end over the fake session restore.
@riverpod
class SignInViewModel extends _$SignInViewModel {
  @override
  Future<AuthSession?> build() =>
      ref.watch(authRepositoryProvider).restoreSession();
}
