import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/manual_measure_row.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// ManualMeasureRow (Figma 66:695) — `state` default/active/error (+ the
/// MI-13 inch display), both themes.
void main() {
  themedGoldenTest(
    'ManualMeasureRow matrix',
    fileName: 'manual_measure_row',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'default · cm',
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
        GoldenTestScenario(
          name: 'active · cm',
          child: SizedBox(
            width: 360,
            child: ManualMeasureRow(
              name: 'chest',
              valueCm: 96,
              active: true,
              onChanged: (_) {},
              unit: MeasureUnit.cm,
              onUnitChanged: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'error · double-check hint (never a hard block)',
          child: SizedBox(
            width: 360,
            child: ManualMeasureRow(
              name: 'waist',
              valueCm: 205,
              error: 'That looks unusually high — double-check the tape.',
              onChanged: (_) {},
              unit: MeasureUnit.cm,
              onUnitChanged: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'default · in (MI-13 flip)',
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
      ],
    ),
  );
}
