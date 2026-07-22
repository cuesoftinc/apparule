import 'package:flutter/foundation.dart' show protected;

/// Throw-once failure seam for the `*Fake` repositories (the interaction
/// audit's CLASS 4 lock): fakes that never throw leave every screen's
/// failure path latent — tests arm [failNext] and the next mutating call
/// throws it instead of mutating, then the seam disarms.
///
/// Contract-test recipe (one per mutating surface, owned by the lanes):
/// arm the seam, fire the action, assert the failure toast showed and the
/// user's input survived (`runAction` semantics).
mixin FailNextSeam {
  /// The failure the next mutating call throws — [Exception] or [Error]
  /// (the lifecycle fakes' native StateError shape both count). Null =
  /// disarmed (the default; mutations succeed).
  Object? failNext;

  /// Mutating methods call this first: throws (and disarms) any armed
  /// failure before touching state.
  @protected
  void maybeFailNext() {
    if (failNext case final failure?) {
      failNext = null;
      // The armed value is an Exception or Error by contract; the seam
      // just re-throws whatever the test chose.
      // ignore: only_throw_errors
      throw failure;
    }
  }
}
