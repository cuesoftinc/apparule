import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/capture_option_card.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// CaptureOptionCard (Figma 66:721) — `mode` webcam-upload/manual-entry,
/// both themes.
void main() {
  themedGoldenTest(
    'CaptureOptionCard matrix',
    fileName: 'capture_option_card',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        for (final mode in CaptureOptionMode.values)
          GoldenTestScenario(
            name: mode.name,
            child: SizedBox(
              width: 340,
              child: CaptureOptionCard(mode: mode, onTap: () {}),
            ),
          ),
      ],
    ),
  );
}
