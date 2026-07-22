import 'package:apparule/src/core/ui/sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('Sheet', () {
    testWidgets('renders the centred title and a named close control', (
      tester,
    ) async {
      var closes = 0;
      await tester.pumpApp(
        Sheet(
          title: 'Report post',
          onClose: () => closes++,
          child: const Text('Body'),
        ),
      );

      expect(find.text('Report post'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pump();

      expect(closes, 1);
    });

    testWidgets('stepper header renders the MI-10 caption', (tester) async {
      await tester.pumpApp(
        const Sheet(
          title: 'Request outfit',
          stepper: SheetStepper(
            steps: <String>['Measurements', 'Notes & budget', 'Review'],
            current: 1,
          ),
          child: Text('Body'),
        ),
      );

      expect(find.text('Step 2 of 3 · Notes & budget'), findsOneWidget);
    });

    testWidgets('Sheet.show presents and Close dismisses', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Sheet.show<void>(
                  context,
                  title: 'Report post',
                  child: const Text('Body'),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Sheet), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(Sheet), findsNothing);
    });
  });
}
