import 'package:apparule/src/core/ui/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('Button', () {
    testWidgets('tap fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: Button(label: 'Continue', onPressed: () => taps++),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(taps, 1);
    });

    testWidgets('disabled (onPressed null) ignores taps', (tester) async {
      await tester.pumpApp(
        const Center(child: Button(label: 'Continue', onPressed: null)),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(Button),
          matching: find.byType(Semantics),
        ),
      );
      expect(semantics.properties.enabled, isFalse);

      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('loading swaps the label for a spinner and blocks taps', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: Button(
            label: 'Continue',
            loading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Continue'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The semantics label still announces the action (a11y).
      expect(find.bySemanticsLabel('Continue'), findsOneWidget);

      await tester.tap(find.byType(Button));
      await tester.pump(const Duration(milliseconds: 50));
      expect(taps, 0);
    });

    testWidgets('quiet-danger kind renders its label', (tester) async {
      await tester.pumpApp(
        Center(
          child: Button(
            label: 'Delete',
            kind: ButtonKind.quietDanger,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
