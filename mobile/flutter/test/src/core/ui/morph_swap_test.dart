import 'package:apparule/src/core/ui/morph_swap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// MorphSwap (MI-7): a keyed child swap cross-morphs over 150ms — both
/// states exist mid-morph and only the new one after.
void main() {
  Widget host(String state) =>
      MorphSwap(child: Text(state, key: ValueKey<String>(state)));

  testWidgets('the swap runs the 150ms morph — both children mid-flight, '
      'the new one after', (tester) async {
    await tester.pumpApp(host('Follow'));
    expect(find.text('Follow'), findsOneWidget);

    await tester.pumpApp(host('Following'));
    await tester.pump(const Duration(milliseconds: 75));

    // Mid-morph: the outgoing and incoming states coexist.
    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Follow'), findsNothing);
    expect(find.text('Following'), findsOneWidget);
  });

  test('the morph duration is the §4 exact value', () {
    expect(MorphSwap.duration, const Duration(milliseconds: 150));
  });

  testWidgets('an unkeyed-state rebuild does not morph', (tester) async {
    await tester.pumpApp(host('Follow'));
    await tester.pumpApp(host('Follow'));
    await tester.pump(const Duration(milliseconds: 75));
    expect(find.text('Follow'), findsOneWidget);
  });
}
