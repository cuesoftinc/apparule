import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// Sheet (Figma 50:296) — `stepper` false/true · `size` default/wide
/// (the `platform` axis resolves to mobile by construction), both themes.
void main() {
  const body = Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Text('Sheet body content'),
  );

  themedGoldenTest(
    'Sheet matrix',
    fileName: 'sheet',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'default · stepper false',
          child: const SizedBox(
            width: 390,
            height: 220,
            child: Sheet(title: 'Report post', child: body),
          ),
        ),
        GoldenTestScenario(
          name: 'default · stepper true (step 1 of 3, MI-10)',
          child: const SizedBox(
            width: 390,
            height: 260,
            child: Sheet(
              title: 'Request outfit',
              stepper: SheetStepper(
                steps: <String>['Measurements', 'Notes & budget', 'Review'],
                current: 0,
              ),
              child: body,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'default · stepper true (step 3 of 3)',
          child: const SizedBox(
            width: 390,
            height: 260,
            child: Sheet(
              title: 'Request outfit',
              stepper: SheetStepper(
                steps: <String>['Measurements', 'Notes & budget', 'Review'],
                current: 2,
              ),
              child: body,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'wide (tablet width cap)',
          child: const SizedBox(
            width: 700,
            height: 220,
            child: Sheet(
              title: 'Post detail',
              size: SheetSize.wide,
              child: body,
            ),
          ),
        ),
      ],
    ),
  );
}
