import 'package:apparule/src/app/bootstrap.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';

/// prd entrypoint. Still on the fake override set: `*Remote` repositories
/// and Firebase init arrive with the API/auth waves (§1 phase 4), which
/// swap ONLY this override list — no screen or ViewModel changes, by
/// construction (mobile-implementation.md §6).
Future<void> main() => bootstrap(
  flavor: AppFlavor.prd,
  overrides: fakeRepositoryOverrides(),
);
