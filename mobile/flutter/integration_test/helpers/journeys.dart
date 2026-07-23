import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../../test/helpers/boot_app.dart';
import '../../test/helpers/in_memory_persistence.dart';

/// Patrol journey harness (mobile-implementation.md §8 gate 5): boots the
/// SAME composition as the dev entrypoint — the full app over
/// `fakeRepositoryOverrides` — inside the on-device integration_test
/// binding, with `patrol_finders` driving it in real time.
///
/// Timeouts are generous because these run on cold CI emulators: the
/// first frame pays shader compilation, and the C6 auto-capture spends
/// real seconds per pose (align beat + 3-2-1 countdown).
const PatrolTesterConfig journeyConfig = PatrolTesterConfig(
  existsTimeout: Duration(seconds: 30),
  visibleTimeout: Duration(seconds: 30),
);

/// Boots the full app (router included) the way `main_dev.dart` composes
/// it, hermetically per journey: fresh in-memory persistence (each test
/// owns its session lifecycle regardless of what an earlier journey left
/// on the device) and mocked SharedPreferences.
///
/// [signedIn] pre-seeds the persisted session marker, so the journey
/// cold-starts through the REAL restore gate as a returning user;
/// signed-out boots land on C1. [firstActionSeen] mirrors the C1b flag —
/// false replays the first-ever sign-in. [measurementRepository] and
/// [earningsRepository] are the §6 seams journeys re-seed (empty vault
/// for the first capture, the designer ledger for C14).
Future<void> bootJourneyApp(
  PatrolTester $, {
  bool signedIn = true,
  bool firstActionSeen = true,
  MeasurementRepository? measurementRepository,
  EarningsRepository? earningsRepository,
}) async {
  final persistence = InMemoryPersistenceService();
  if (signedIn) {
    persistence.sessionToken = AuthRepositoryFake.fakeSessionToken;
  }
  await pumpBootedApp(
    $.tester,
    // No pumpAndSettle at boot — the home feed skeletons shimmer; the
    // journeys wait on visible outcomes instead.
    settle: false,
    persistenceService: persistence,
    measurementRepository: measurementRepository,
    earningsRepository: earningsRepository,
    preferences: <String, Object>{
      if (firstActionSeen) 'first_action_seen': true,
    },
  );
  await $.pumpAndTrySettle();
}

/// Serves every dev seed EXCEPT the vault sessions — the first-capture
/// user (no height on file, flows/vault.md §1): the capture journey
/// walks the height step, and the vault ends the journey holding exactly
/// the one session it just saved.
class EmptyVaultSeedBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.endsWith('vault_sessions.json')) {
      throw FlutterError('Unable to load asset: $key');
    }
    return rootBundle.load(key);
  }
}
