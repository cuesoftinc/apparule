import 'package:flutter/widgets.dart';

/// EdgeResistPhysics — the MI-4 edge-resist bounce (design.md §4:
/// "edge-resist bounce at ends") as a named physics: iOS-feel bouncing on
/// BOTH platforms, so Android carousels resist at their ends instead of
/// glowing (D59's root cause was default platform physics).
///
/// A named subclass rather than a bare [BouncingScrollPhysics] so the
/// MI-registry conformance harness can assert the idiom by type.
class EdgeResistPhysics extends BouncingScrollPhysics {
  const EdgeResistPhysics({super.parent});

  @override
  EdgeResistPhysics applyTo(ScrollPhysics? ancestor) =>
      EdgeResistPhysics(parent: buildParent(ancestor));
}
