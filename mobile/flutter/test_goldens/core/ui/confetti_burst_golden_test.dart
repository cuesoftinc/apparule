import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/confetti_burst.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/golden_themes.dart';

/// ConfettiBurst (MI-10) — the settled scatter behind the success ✓ via
/// the golden-freeze flag, both themes.
void main() {
  themedGoldenTest(
    'ConfettiBurst',
    fileName: 'confetti_burst',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'settled scatter (frozen)',
          child: const SizedBox(
            width: 320,
            height: 220,
            child: _FrozenBurst(),
          ),
        ),
      ],
    ),
  );
}

class _FrozenBurst extends StatelessWidget {
  const _FrozenBurst();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ConfettiBurst(
      colors: <Color>[
        colors.accentStart,
        colors.accentEnd,
        colors.success,
        colors.warn,
      ],
      frozen: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Icon(LucideIcons.check, size: 48, color: colors.success),
      ),
    );
  }
}
