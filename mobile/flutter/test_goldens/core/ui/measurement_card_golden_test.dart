import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// MeasurementCard (Figma 48:208) — `source` scan/manual · `confidence`
/// normal/low · `sparkline` true/false (manual ⇒ confidence null,
/// capture-qc.md §4), both themes; tnum on every value.
void main() {
  const history = <double>[41.2, 41.8, 41.5, 42, 42.5];

  themedGoldenTest(
    'MeasurementCard matrix',
    fileName: 'measurement_card',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        GoldenTestScenario(
          name: 'scan · normal · sparkline false',
          child: const SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'shoulder_width',
              valueCm: 42.5,
              source: MeasurementSource.scan,
              confidence: 0.92,
              updatedLabel: 'Updated 2d ago',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'scan · low · sparkline false',
          child: const SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'inseam',
              valueCm: 78.5,
              source: MeasurementSource.scan,
              confidence: 0.55,
              updatedLabel: 'Updated 2d ago',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'scan · normal · sparkline true',
          child: const SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'chest',
              valueCm: 96,
              source: MeasurementSource.scan,
              confidence: 0.88,
              history: history,
              updatedLabel: 'Updated 12d ago',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'manual · confidence null · sparkline true',
          child: const SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'waist',
              valueCm: 81,
              source: MeasurementSource.manual,
              history: history,
              updatedLabel: 'Updated 40d ago',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'manual · cm display (MI-13 toggle)',
          child: const SizedBox(
            width: 240,
            child: MeasurementCard(
              name: 'waist',
              valueCm: 81,
              unit: MeasureUnit.cm,
              source: MeasurementSource.manual,
            ),
          ),
        ),
      ],
    ),
  );
}
