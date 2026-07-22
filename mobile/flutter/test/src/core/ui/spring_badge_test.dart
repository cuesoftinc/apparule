import 'package:apparule/src/core/ui/spring_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// SpringBadge (MI-16): the count pill pops with a springy scale on
/// INCREMENTS only, renders nothing at zero, and rests at exactly 1.0
/// scale (golden stability).
void main() {
  double scaleOf(WidgetTester tester) => tester
      .widget<ScaleTransition>(find.byType(ScaleTransition))
      .scale
      .value;

  testWidgets('renders the formatted count; nothing at zero', //
  (tester) async {
    await tester.pumpApp(const SpringBadge(count: 3));
    expect(find.text('3'), findsOneWidget);

    await tester.pumpApp(const SpringBadge(count: 0));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('an increment pops the springy scale, then settles back '
      'to 1', (tester) async {
    await tester.pumpApp(const SpringBadge(count: 2));
    expect(scaleOf(tester), 1);

    await tester.pumpApp(const SpringBadge(count: 3));
    await tester.pump(const Duration(milliseconds: 120));
    expect(scaleOf(tester), greaterThan(1));

    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
  });

  testWidgets('a decrement stays still (the pop announces news)', //
  (tester) async {
    await tester.pumpApp(const SpringBadge(count: 3));
    await tester.pumpApp(const SpringBadge(count: 2));
    await tester.pump(const Duration(milliseconds: 120));
    expect(scaleOf(tester), 1);
  });
}
