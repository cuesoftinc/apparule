import 'package:apparule/src/core/ui/manual_measure_row.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('ManualMeasureRow', () {
    Widget row({
      double? valueCm = 42.5,
      MeasureUnit unit = MeasureUnit.cm,
      String? error,
      ValueChanged<double?>? onChanged,
      ValueChanged<MeasureUnit>? onUnitChanged,
    }) {
      return SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: ManualMeasureRow(
            name: 'shoulder_width',
            valueCm: valueCm,
            unit: unit,
            error: error,
            onChanged: onChanged ?? (_) {},
            onUnitChanged: onUnitChanged ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('renders the humanized label and current value', (
      tester,
    ) async {
      await tester.pumpApp(row());

      expect(find.text('Shoulder Width'), findsOneWidget);
      expect(find.text('42.5'), findsOneWidget);
      expect(find.text('cm'), findsOneWidget);
    });

    testWidgets('unit toggle flips cm → in (MI-13)', (tester) async {
      final units = <MeasureUnit>[];
      await tester.pumpApp(row(onUnitChanged: units.add));

      await tester.tap(find.bySemanticsLabel('Switch to in'));
      await tester.pump();

      expect(units, <MeasureUnit>[MeasureUnit.inch]);
    });

    testWidgets('tapping the tape slider reports a stepped value', (
      tester,
    ) async {
      final values = <double?>[];
      await tester.pumpApp(row(onChanged: values.add));

      final slider = find.bySemanticsLabel('Shoulder Width slider');
      final rect = tester.getRect(slider);
      await tester.tapAt(rect.centerRight - const Offset(4, 0));
      await tester.pump();

      expect(values, hasLength(1));
      expect(values.single, isNotNull);
      // 0.5cm steps within the 10–200 sanity range.
      expect(values.single! * 2, values.single! * 2 ~/ 1);
      expect(values.single, greaterThan(100));
    });

    testWidgets('advisory error copy renders (never a hard block)', (
      tester,
    ) async {
      await tester.pumpApp(
        row(valueCm: 205, error: 'That looks unusually high.'),
      );

      expect(find.text('That looks unusually high.'), findsOneWidget);
    });
  });
}
