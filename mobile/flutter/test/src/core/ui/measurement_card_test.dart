import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('MeasurementCard', () {
    testWidgets('renders the humanized name and one-decimal value — '
        'inches by default (A-9)', (tester) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'shoulder_width',
              valueCm: 42.5,
              source: MeasurementSource.scan,
              confidence: 0.92,
            ),
          ),
        ),
      );

      expect(find.text('Shoulder Width'), findsOneWidget);
      expect(find.text('16.7 in'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.textContaining('Low confidence'), findsNothing);
    });

    testWidgets('cm display converts when the toggle flips (MI-13)', (
      tester,
    ) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'waist',
              valueCm: 81,
              unit: MeasureUnit.cm,
              source: MeasurementSource.manual,
            ),
          ),
        ),
      );

      expect(find.text('81.0 cm'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
    });

    testWidgets('confidence under 0.7 renders the warn chip', (tester) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'inseam',
              valueCm: 78.5,
              source: MeasurementSource.scan,
              confidence: 0.55,
            ),
          ),
        ),
      );

      expect(find.text('Low confidence · 0.55'), findsOneWidget);
    });

    testWidgets('history > 1 renders the sparkline painter', (
      tester,
    ) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'chest',
              valueCm: 96,
              source: MeasurementSource.scan,
              history: <double>[41.2, 41.8, 42.5],
            ),
          ),
        ),
      );

      final paints = find.descendant(
        of: find.byType(MeasurementCard),
        matching: find.byType(CustomPaint),
      );
      expect(paints, findsWidgets);
    });

    testWidgets('tap fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'chest',
              valueCm: 96,
              source: MeasurementSource.scan,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MeasurementCard));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
