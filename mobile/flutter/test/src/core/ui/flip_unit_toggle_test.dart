import 'package:apparule/src/core/ui/flip_unit_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// FlipUnitToggle (MI-13): the keyed unit swap flips with an x-rotation
/// over the 200ms base token.
void main() {
  Widget host(String unit) =>
      FlipUnitToggle(child: Text(unit, key: ValueKey<String>(unit)));

  testWidgets('the unit swap flips: mid-flight both units render inside '
      'x-rotation transforms', (tester) async {
    await tester.pumpApp(host('cm'));
    expect(find.text('cm'), findsOneWidget);

    await tester.pumpApp(host('in'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('cm'), findsOneWidget);
    expect(find.text('in'), findsOneWidget);

    // The incoming child is mid x-rotation (matrix row 1 leans into z —
    // a perspective rotateX, not a plain paint).
    final transform = tester.widget<Transform>(
      find
          .ancestor(of: find.text('in'), matching: find.byType(Transform))
          .first,
    );
    expect(transform.transform.getRow(1).z, isNot(0));

    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('cm'), findsNothing);
    expect(find.text('in'), findsOneWidget);
  });

  testWidgets('at rest the child renders flat (no residual rotation)', //
  (tester) async {
    await tester.pumpApp(host('cm'));
    await tester.pumpAndSettle();
    expect(find.text('cm'), findsOneWidget);
  });
}
