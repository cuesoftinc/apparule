import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';

/// Empty-state fake — the seeded §6 narrative (assets/seed/) arrives with
/// the screens wave; the interface seam is what this wave establishes.
class ProfileRepositoryFake implements ProfileRepository {
  @override
  Future<Profile?> me() async => null;
}
