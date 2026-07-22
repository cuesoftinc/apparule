import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// QCHintChip (Figma 62:634) — all 11 `code` cells (1:1 with the
/// capture-qc.md fail codes), both themes.
void main() {
  themedGoldenTest(
    'QCHintChip matrix',
    fileName: 'qc_hint_chip',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        for (final code in QcFailCode.values)
          GoldenTestScenario(
            name: code.wireName,
            child: QCHintChip(code: code),
          ),
      ],
    ),
  );
}
