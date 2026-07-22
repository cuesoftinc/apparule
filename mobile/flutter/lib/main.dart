import 'package:apparule/src/app/bootstrap.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/utils/app_flavor.dart';

/// prod entrypoint (the default) — CueLABS production runs on the sandbox
/// account (org environment ruling, user directive 2026-07-22): bare
/// applicationId `io.cuesoft.apparule`, Firebase `sandbox-e306a`, env
/// from the Doppler `apparule/stg` config (the config NAME stays `stg`).
///
/// Still on the fake override set: the real auth swap is one diff here
/// once `flutterfire configure` lands `firebase_options.dart` (blocked on
/// `firebase login --reauth`) —
///
/// ```dart
/// bootstrap(
///   flavor: AppFlavor.prod,
///   firebaseOptions: DefaultFirebaseOptions.currentPlatform,
///   overrides: <Override>[
///     ...fakeRepositoryOverrides(),
///     firebaseAuthRepositoryOverride(),
///   ],
/// )
/// ```
///
/// — no screen or ViewModel changes, by construction
/// (mobile-implementation.md §6/§9). `*Remote` repositories follow with
/// the API wave (§1 phase 4) the same way.
Future<void> main() => bootstrap(
  flavor: AppFlavor.prod,
  overrides: fakeRepositoryOverrides(),
);
