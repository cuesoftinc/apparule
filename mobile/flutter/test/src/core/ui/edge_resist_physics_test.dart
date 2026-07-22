import 'package:apparule/src/core/ui/edge_resist_physics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// EdgeResistPhysics (MI-4): named bouncing physics — overscroll is
/// permitted (resist-and-spring, no clamp/glow) and the type survives
/// `applyTo` so the MI-registry can assert it.
void main() {
  test('applyTo preserves the named type (position setups clone physics)', //
  () {
    final applied = const EdgeResistPhysics().applyTo(
      const AlwaysScrollableScrollPhysics(),
    );
    expect(applied, isA<EdgeResistPhysics>());
    expect(applied.parent, isA<AlwaysScrollableScrollPhysics>());
  });

  test('overscroll is unclamped — the edge resists instead of stopping', //
  () {
    const physics = EdgeResistPhysics();
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 100,
      pixels: 0,
      viewportDimension: 600,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    // Bouncing semantics: no boundary clamp at the edge…
    expect(physics.applyBoundaryConditions(metrics, -10), 0);
    // …and a top-edge pull still accepts user offset.
    expect(physics.shouldAcceptUserOffset(metrics), isTrue);
  });
}
