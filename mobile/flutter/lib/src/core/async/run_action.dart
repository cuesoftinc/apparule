import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// The one mutation-failure seam for screens (the audit's CLASS 4 lock —
/// the mobile mirror of web's `run()`): await the [action]; on failure
/// roll back, toast, and report `false` so the caller keeps the user's
/// input (composers clear ONLY on success).
///
/// Order of operations on failure: [rollback] first (the surface returns
/// to its pre-action truth), then the SnackBar toast ([failureText],
/// defaulting to the shared l10n copy). Errors are swallowed after the
/// toast — `runAction` IS the handler; nothing rethrows into the zone.
/// The catch is deliberately `on Object`: fake repositories signal
/// illegal lifecycle moves with [StateError] (an `Error`), and a silent
/// wedge is worse than a broad catch at the UI boundary.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  VoidCallback? rollback,
  String? failureText,
}) async {
  try {
    await action();
    return true;
  } on Object {
    rollback?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureText ?? context.l10n.actionFailedToast)),
      );
    }
    return false;
  }
}
