import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_screen.dart';

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C1 — the single Google-CTA auth screen (canvas 167:13): gradient
/// wordmark + tagline, one CTA, legal links; both themes.
void main() {
  themedGoldenTest(
    'SignInScreen',
    fileName: 'sign_in_screen',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'wordmark + CTA + legal links',
          child: screenFrame(const SignInScreen()),
        ),
      ],
    ),
  );
}
