import 'package:flutter_test/flutter_test.dart';

/// Runs the test under the platform's reduced-motion flag.
///
/// Screens hosting REPEATING MI primitives (the MI-14 current-dot pulse,
/// the MI-17 typing wave) never settle under `pumpAndSettle`; the
/// primitives all implement the design.md §5 reduced-motion fallback
/// (static render, same anatomy), so wiring/transition suites run with
/// animations disabled and the motion itself stays covered by each
/// primitive's own bounded-pump unit tests.
void disableTestAnimations(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}
