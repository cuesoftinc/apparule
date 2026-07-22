import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Alchemist configuration for the golden suites (mobile-implementation.md
/// §7/§8): CI goldens only — text renders as blocked boxes, so the
/// committed images are byte-identical across platforms (the reason
/// alchemist replaced the discontinued golden_toolkit). Platform goldens
/// are disabled so macOS dev machines never generate a second,
/// platform-dependent set.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
