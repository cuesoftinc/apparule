import 'package:apparule/src/app/bootstrap.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';

/// dev entrypoint — runs entirely over `*Fake` repositories
/// (mobile-implementation.md §6, the mobile analogue of web's TEST_MODE).
/// Boots signed in as the seeded §6 test user (`kiki.adeyemi`), so local
/// iteration lands straight in the tab shell; sign out from Profile (or
/// seed `null` here) to work on C1.
Future<void> main() => bootstrap(
  flavor: AppFlavor.dev,
  overrides: fakeRepositoryOverrides(
    authRepository: AuthRepositoryFake(
      initialSession: AuthRepositoryFake.seedSession,
    ),
  ),
);
