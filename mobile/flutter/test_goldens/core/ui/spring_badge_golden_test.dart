import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/spring_badge.dart';

import '../../helpers/golden_themes.dart';

/// SpringBadge (MI-16) — the count pill at rest across count widths,
/// both themes (the pop itself is behavior; rest scale is exactly 1).
void main() {
  themedGoldenTest(
    'SpringBadge',
    fileName: 'spring_badge',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: <GoldenTestScenario>[
        for (final count in <int>[1, 12, 1200])
          GoldenTestScenario(
            name: 'count $count',
            child: SpringBadge(count: count),
          ),
      ],
    ),
  );
}
