import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/typing_bubble.dart';

import '../../helpers/golden_themes.dart';

/// TypingBubble (MI-17) — the responding bubble at a fixed wave frame,
/// both themes.
void main() {
  themedGoldenTest(
    'TypingBubble',
    fileName: 'typing_bubble',
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'responding pulse',
          child: const TypingBubble(),
        ),
      ],
    ),
  );
}
