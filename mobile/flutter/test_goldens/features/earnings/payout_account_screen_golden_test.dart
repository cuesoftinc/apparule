import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/presentation/payout_account_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C13 payout form (canvas 205:2 family) — the idle banking form with
/// the Paystack intro/footer, both themes. (The resolving/resolved/
/// failed states are interaction states — widget tests assert their
/// copy; the chrome is this frame.)
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'PayoutAccountScreen idle',
    fileName: 'payout_account_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'idle form',
          child: screenFrame(
            const PayoutAccountScreen(),
            earningsRepository: EarningsRepositoryFake(
              viewer: 'amara.designs',
              now: () => pinned,
              resolveDelay: Duration.zero,
            ),
          ),
        ),
      ],
    ),
  );
}
