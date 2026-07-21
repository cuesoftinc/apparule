import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';

/// Empty-state fake — the seeded §6 narrative (assets/seed/) arrives with
/// the screens wave; the interface seam is what this wave establishes.
class AuthRepositoryFake implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession() async => null;
}
