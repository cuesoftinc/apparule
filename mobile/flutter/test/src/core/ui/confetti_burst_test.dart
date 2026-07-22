import 'package:apparule/src/core/ui/confetti_burst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// ConfettiBurst (MI-10): animates once within the ≤800ms budget, then
/// holds the deterministic scatter; the frozen flag skips straight to it.
void main() {
  const colors = <Color>[Color(0xFFE1306C), Color(0xFFF77737)];

  Widget host({bool frozen = false}) => SizedBox(
    width: 300,
    height: 220,
    child: ConfettiBurst(
      colors: colors,
      frozen: frozen,
      child: const Center(child: Text('✓')),
    ),
  );

  testWidgets(
    'animates once and settles within the 800ms budget', //
    (tester) async {
      await tester.pumpApp(host());
      expect(find.text('✓'), findsOneWidget);

      // Still animating mid-burst…
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.hasRunningAnimations, isTrue);

      // …settled by the budget — no repeating animation to wedge
      // pumpAndSettle (the §4 "once per order" shape).
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('frozen renders the settled scatter with no animation '
      '(the golden-freeze flag)', (tester) async {
    await tester.pumpApp(host(frozen: true));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('✓'), findsOneWidget);
  });

  test('the burst budget is the §4 exact value', () {
    expect(ConfettiBurst.duration, const Duration(milliseconds: 800));
  });
}
