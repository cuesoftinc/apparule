import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/account_data_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// B7 Account & data (canvas 207:7182) — identity, export-first, the
/// quiet-danger delete row, log out, both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'AccountDataScreen seeded',
    fileName: 'account_data_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'export + danger zone',
          child: screenFrame(
            const AccountDataScreen(),
            profileRepository: ProfileRepositoryFake(now: () => pinned),
          ),
        ),
      ],
    ),
  );
}
