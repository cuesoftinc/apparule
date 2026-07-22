import 'dart:async' show unawaited;

import 'package:flutter/services.dart' show HapticFeedback;

/// The MI-20 haptic vocabulary (design.md §4) as one shared primitive —
/// light: like/save/refresh trigger; medium: request submitted, payment
/// success; error buzz: capture failed.
///
/// Screens and components call these named intents, never
/// [HapticFeedback] directly (the audit's CLASS 6 lock: every MI idiom is
/// buildable-by-reference or it gets skipped per-screen). The platform
/// futures are fire-and-forget by construction — haptics never gate UI.
abstract final class AppHaptics {
  /// MI-20 light impact — social engagement (like, save, double-tap) and
  /// the MI-5 pull-to-refresh trigger.
  static void light() => unawaited(HapticFeedback.lightImpact());

  /// MI-20 medium impact — request submitted, payment success.
  static void medium() => unawaited(HapticFeedback.mediumImpact());

  /// MI-20 error buzz — capture failed.
  static void error() => unawaited(HapticFeedback.vibrate());
}
