import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/processing_constellation.dart';
import 'package:flutter/material.dart';
import '../../helpers/golden_themes.dart';
import '../../helpers/test_images.dart';

/// ProcessingConstellation (Figma 64:748) — `state`
/// processing/success/failed, both themes. Landmarks pulse while
/// processing (MI-12), so the suite pumps a fixed frame after precaching
/// the stand-in photo.
void main() {
  themedGoldenTest(
    'ProcessingConstellation matrix',
    fileName: 'processing_constellation',
    pumpBeforeTest: precacheThenFrame,
    builder: () => GoldenTestGroup(
      columns: 3,
      children: <Widget>[
        for (final state in ProcessingState.values)
          GoldenTestScenario(
            name: state.name,
            child: SizedBox(
              width: 240,
              child: ProcessingConstellation(
                state: state,
                image: grayPixelImage,
              ),
            ),
          ),
      ],
    ),
  );
}
