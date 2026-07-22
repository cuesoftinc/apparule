import 'package:apparule/src/core/ui/typing_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// TypingBubble (MI-17): three dots in one announced bubble, pulsing in a
/// staggered wave.
void main() {
  testWidgets('renders three pulsing dots behind one "Responding" '
      'semantics node', (tester) async {
    await tester.pumpApp(const TypingBubble());

    final dots = find.descendant(
      of: find.byType(TypingBubble),
      matching: find.byType(FadeTransition),
    );
    expect(find.bySemanticsLabel('Responding'), findsOneWidget);
    expect(dots, findsNWidgets(3));

    // The wave staggers: mid-cycle the three dots sit at different
    // opacities.
    await tester.pump(const Duration(milliseconds: 300));
    final opacities = tester
        .widgetList<FadeTransition>(dots)
        .map((fade) => fade.opacity.value)
        .toList();
    expect(opacities.toSet().length, greaterThan(1));
  });
}
