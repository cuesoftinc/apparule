import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// MI-13 manual entry — the v1 vocabulary over ManualMeasureRow, both
/// themes.
void main() {
  themedGoldenTest(
    'ManualEntryScreen',
    fileName: 'manual_entry_screen',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'empty vocabulary, save disabled',
          child: screenFrame(const ManualEntryScreen()),
        ),
      ],
    ),
  );
}
