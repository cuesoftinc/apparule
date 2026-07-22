import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C14 (canvas 267:8613) — the amara ledger story (₦82,500 available /
/// ₦45,000 escrow, tabular rows) and the non-designer empty state,
/// both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Override pinnedClock() => clockProvider.overrideWith(
    (ref) =>
        () => pinned,
  );

  themedGoldenTest(
    'EarningsScreen seeded',
    fileName: 'earnings_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'designer ledger (amara)',
          child: screenFrame(
            const EarningsScreen(),
            earningsRepository: EarningsRepositoryFake(
              viewer: 'amara.designs',
              now: () => pinned,
              resolveDelay: Duration.zero,
            ),
            overrides: <Override>[pinnedClock()],
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'EarningsScreen non-designer',
    fileName: 'earnings_screen_empty',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'become a designer',
          child: screenFrame(
            const EarningsScreen(),
            earningsRepository: EarningsRepositoryFake(
              now: () => pinned,
              resolveDelay: Duration.zero,
            ),
            overrides: <Override>[pinnedClock()],
          ),
        ),
      ],
    ),
  );
}
