import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/auth/presentation/first_action_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C1b — the post-signup interstitial (canvas 266:2): personalised
/// welcome, the two choice cards, "Skip for now"; both themes.
void main() {
  themedGoldenTest(
    'FirstActionScreen',
    fileName: 'first_action_screen',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'welcome + choice cards',
          child: screenFrame(
            const FirstActionScreen(),
            authRepository: AuthRepositoryFake(
              initialSession: AuthRepositoryFake.seedSession,
            ),
          ),
        ),
      ],
    ),
  );
}
