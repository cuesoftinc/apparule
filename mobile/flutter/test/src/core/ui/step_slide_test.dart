import 'package:apparule/src/core/ui/step_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// StepSlide (MI-10): keyed step swaps slide the incoming body 24px —
/// from the right going forward, from the left in reverse.
void main() {
  Widget host(int step, {bool reverse = false}) => StepSlide(
    reverse: reverse,
    child: Text('step $step', key: ValueKey<int>(step)),
  );

  double incomingDx(WidgetTester tester, String text) {
    final transform = tester.widget<Transform>(
      find.ancestor(of: find.text(text), matching: find.byType(Transform)),
    );
    return transform.transform.getTranslation().x;
  }

  testWidgets('forward: the incoming step slides in from +24px', //
  (tester) async {
    await tester.pumpApp(host(1));
    await tester.pumpApp(host(2));
    await tester.pump(const Duration(milliseconds: 50));

    final dx = incomingDx(tester, 'step 2');
    expect(dx, greaterThan(0));
    expect(dx, lessThanOrEqualTo(StepSlide.distance));

    await tester.pumpAndSettle();
    expect(find.text('step 1'), findsNothing);
    expect(incomingDx(tester, 'step 2'), 0);
  });

  testWidgets('reverse: the incoming step slides in from −24px', //
  (tester) async {
    await tester.pumpApp(host(2));
    await tester.pumpApp(host(1, reverse: true));
    await tester.pump(const Duration(milliseconds: 50));

    expect(incomingDx(tester, 'step 1'), lessThan(0));
    await tester.pumpAndSettle();
  });

  test('the slide distance is the §4 exact value', () {
    expect(StepSlide.distance, 24);
  });
}
