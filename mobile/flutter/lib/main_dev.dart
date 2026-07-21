import 'package:apparule/src/app/bootstrap.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';

/// dev entrypoint — runs entirely over `*Fake` repositories
/// (mobile-implementation.md §6, the mobile analogue of web's TEST_MODE).
Future<void> main() => bootstrap(
  flavor: AppFlavor.dev,
  overrides: fakeRepositoryOverrides(),
);
