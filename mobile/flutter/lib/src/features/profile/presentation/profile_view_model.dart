import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_view_model.g.dart';

/// C9 placeholder ViewModel — watches the abstract profile repository;
/// dev/stg overrides supply the fake.
@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  @override
  Future<Profile?> build() => ref.watch(profileRepositoryProvider).me();
}
