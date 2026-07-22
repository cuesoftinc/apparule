import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C7 vault (canvas 173:698) — the MI-11 freshness-ring header over the
/// metric-centric MeasurementCards (sparklines + updated labels) and the
/// consent note/rights links, both themes. One pinned instant drives the
/// seeded fake AND the screen clock, so freshness stays byte-stable.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'VaultScreen seeded',
    fileName: 'vault_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'freshness header + metric cards',
          child: screenFrame(
            const VaultScreen(),
            measurementRepository: MeasurementRepositoryFake(now: () => pinned),
            overrides: <Override>[
              clockProvider.overrideWith(
                (ref) =>
                    () => pinned,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
