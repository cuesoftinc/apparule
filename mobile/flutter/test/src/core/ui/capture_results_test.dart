import 'package:apparule/src/core/ui/capture_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('CaptureResults', () {
    Widget results({
      required List<double> confidences,
      bool saving = false,
      VoidCallback? onSave,
      VoidCallback? onRetake,
    }) {
      return SingleChildScrollView(
        child: SizedBox(
          width: 340,
          child: CaptureResults(
            confidences: confidences,
            saving: saving,
            onSave: onSave ?? () {},
            onRetake: onRetake ?? () {},
            children: const <Widget>[
              SizedBox(height: 40, child: Text('card')),
            ],
          ),
        ),
      );
    }

    testWidgets('low confidences drive the warn header pill', (
      tester,
    ) async {
      await tester.pumpApp(results(confidences: <double>[0.9, 0.55]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('1 low confidence'), findsOneWidget);
    });

    testWidgets('all-clear confidences read High confidence', (
      tester,
    ) async {
      await tester.pumpApp(results(confidences: <double>[0.9, 0.95]));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('High confidence'), findsOneWidget);
    });

    testWidgets('Save fires onSave', (tester) async {
      var saves = 0;
      await tester.pumpApp(
        results(confidences: <double>[0.9], onSave: () => saves++),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Save to vault'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(saves, 1);
    });

    testWidgets('saving blocks Retake and spins the primary CTA', (
      tester,
    ) async {
      var retakes = 0;
      await tester.pumpApp(
        results(
          confidences: <double>[0.9],
          saving: true,
          onRetake: () => retakes++,
        ),
      );
      // The saving spinner repeats — fixed frames only.
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Retake'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(retakes, 0);
    });
  });
}
