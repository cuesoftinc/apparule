import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/capture_results.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_themes.dart';

/// CaptureResults (Figma 65:612, single component) — high/low confidence
/// headers + the saving state, both themes. One 1s pump lets the MI-12
/// stagger complete deterministically while the saving spinner freezes on
/// a fixed frame.
void main() {
  Future<void> pumpOneSecond(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
  }

  const cards = <Widget>[
    MeasurementCard(
      name: 'shoulder_width',
      valueCm: 42.5,
      source: MeasurementSource.scan,
      confidence: 0.92,
    ),
    MeasurementCard(
      name: 'inseam',
      valueCm: 78.5,
      source: MeasurementSource.scan,
      confidence: 0.55,
    ),
  ];

  themedGoldenTest(
    'CaptureResults matrix',
    fileName: 'capture_results',
    pumpBeforeTest: pumpOneSecond,
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        GoldenTestScenario(
          name: 'high confidence',
          child: SizedBox(
            width: 340,
            child: CaptureResults(
              confidences: const <double>[0.92, 0.88],
              onSave: () {},
              onRetake: () {},
              children: <Widget>[cards[0]],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'one low confidence',
          child: SizedBox(
            width: 340,
            child: CaptureResults(
              confidences: const <double>[0.92, 0.55],
              onSave: () {},
              onRetake: () {},
              children: cards,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'saving (spinner + retake disabled)',
          child: SizedBox(
            width: 340,
            child: CaptureResults(
              confidences: const <double>[0.92, 0.88],
              saving: true,
              onSave: () {},
              onRetake: () {},
              children: <Widget>[cards[0]],
            ),
          ),
        ),
      ],
    ),
  );
}
