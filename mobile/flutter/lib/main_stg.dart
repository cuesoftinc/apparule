import 'package:apparule/src/app/bootstrap.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';

/// stg entrypoint — fakes, like dev, but flavor-scoped for demo/QA data
/// volumes once the seeded narrative lands (mobile-implementation.md §6).
Future<void> main() => bootstrap(
  flavor: AppFlavor.stg,
  overrides: fakeRepositoryOverrides(),
);
