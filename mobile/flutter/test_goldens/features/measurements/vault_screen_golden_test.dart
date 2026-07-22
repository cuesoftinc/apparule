import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C7 vault — capture-entry cards over the seeded session list, both
/// themes. The fake pins `now`, so the seed's freshness labels
/// ("Measured 12d ago") stay byte-stable.
void main() {
  themedGoldenTest(
    'VaultScreen seeded',
    fileName: 'vault_screen',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'entry cards + seeded sessions',
          child: screenFrame(
            const VaultScreen(),
            measurementRepository: MeasurementRepositoryFake(
              now: () => DateTime.utc(2026, 7, 22, 12),
            ),
          ),
        ),
      ],
    ),
  );
}
