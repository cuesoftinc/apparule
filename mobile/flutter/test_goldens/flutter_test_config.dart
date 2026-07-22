import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Alchemist configuration for the golden suites (mobile-implementation.md
/// §7/§8): CI goldens only, at alchemist's platform-independent defaults
/// (text renders as blocked boxes, shadows render solid — the reason
/// alchemist replaced the discontinued golden_toolkit). Platform goldens
/// are disabled so macOS dev machines never generate a second,
/// platform-dependent set.
///
/// AUTHORING RULE: the committed `goldens/ci/` images are generated on
/// LINUX — the platform the gate compares on — via the `mobile-goldens`
/// workflow (workflow_dispatch → download the `ci-goldens` artifact →
/// commit). Arch-level float differences in anti-aliasing/blur/bilinear
/// filtering leave sub-2% residue between macOS-arm64 renders and the
/// x64 runners even with blocked text, so macOS-generated images must
/// never be committed here. Local `--update-goldens` runs are for
/// eyeballing only. No diff tolerances: the gate is byte-exact.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
