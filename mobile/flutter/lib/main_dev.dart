import 'package:apparule/src/app/bootstrap.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';

/// dev entrypoint — runs entirely over `*Fake` repositories
/// (mobile-implementation.md §6, the mobile analogue of web's TEST_MODE),
/// through the REAL boot flow (boot-flow directive 2026-07-22): cold
/// start → native splash → session-restore gate → C1 on a first-ever
/// launch; the fake "Continue with Google" resolves instantly and
/// persists its session, so later launches restore straight into the tab
/// shell; sign out (Settings → Account & data) purges it and lands back
/// on C1.
Future<void> main() => bootstrap(
  flavor: AppFlavor.dev,
  overrides: fakeRepositoryOverrides(),
);
