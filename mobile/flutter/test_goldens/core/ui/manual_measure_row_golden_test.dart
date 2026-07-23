import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/manual_measure_row.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// ManualMeasureRow (Figma 66:695) — `state` default/active/error in the
/// inches-default display (A-9), plus the MI-13 cm flip, both themes.
void main() {
  themedGoldenTest(
    'ManualMeasureRow matrix',
    fileName: 'manual_measure_row',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'default · in',
          child: SizedBox(
            width: 360,
            child: ManualMeasureRow(
              name: 'shoulder_width',
              valueCm: 42.5,
              onChanged: (_) {},
              unit: MeasureUnit.inch,
              onUnitChanged: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'active · in',
          child: SizedBox(
            width: 360,
            child: ManualMeasureRow(
              name: 'chest',
              valueCm: 96,
              active: true,
              onChanged: (_) {},
              unit: MeasureUnit.inch,
              onUnitChanged: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'error · out-of-range hint (never a hard block)',
          child: SizedBox(
            width: 360,
            child: ManualMeasureRow(
              name: 'waist',
              valueCm: 205,
              // The canvas error cell: the row's canonical 10–200 cm
              // default band rendered in the inches display (4–79 in).
              error: 'Out of range — enter 4 to 79 in',
              onChanged: (_) {},
              unit: MeasureUnit.inch,
              onUnitChanged: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'cm (MI-13 flip)',
          child: SizedBox(
            width: 360,
            child: ManualMeasureRow(
              name: 'shoulder_width',
              valueCm: 42.5,
              onChanged: (_) {},
              unit: MeasureUnit.cm,
              onUnitChanged: (_) {},
            ),
          ),
        ),
      ],
    ),
  );
}
