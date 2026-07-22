import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('CountdownRing', () {
    testWidgets('renders the tick numeral', (tester) async {
      for (final count in CountdownCount.values) {
        await tester.pumpApp(
          Center(child: CountdownRing(count: count)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('${count.value}'), findsOneWidget);
      }
    });

    testWidgets('announces the tick as a live region', (tester) async {
      await tester.pumpApp(
        const Center(child: CountdownRing(count: CountdownCount.two)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsLabel('Capturing in 2'), findsOneWidget);
    });
  });
}
