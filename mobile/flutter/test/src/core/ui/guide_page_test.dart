import 'package:apparule/src/core/ui/guide_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// GuidePage (526:33): one parameterized page per canvas step — the
/// illustration card renders its step's diagram furniture (chips and
/// dimension labels are real text over the CustomPaint vectors) beneath
/// the caller's copy block.
void main() {
  Future<void> pumpStep(WidgetTester tester, GuideStep step) async {
    await tester.pumpApp(
      SingleChildScrollView(
        child: SizedBox(
          width: 390,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GuidePage(
              step: step,
              title: 'Title',
              bullets: const <String>['First bullet', 'Second bullet'],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the copy block (title + bullets)', (tester) async {
    await pumpStep(tester, GuideStep.intro);

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('First bullet'), findsOneWidget);
    expect(find.text('Second bullet'), findsOneWidget);
  });

  testWidgets('intro carries the "Your height" measure chip', (tester) async {
    await pumpStep(tester, GuideStep.intro);
    expect(find.text('Your height'), findsOneWidget);
  });

  testWidgets('ready carries the three preparation chips', (tester) async {
    await pumpStep(tester, GuideStep.ready);
    expect(find.text('Tie hair back'), findsOneWidget);
    expect(find.text('Fitted clothes'), findsOneWidget);
    expect(find.text('Bare feet'), findsOneWidget);
  });

  testWidgets('setup carries the 5–6 ft distance label', (tester) async {
    await pumpStep(tester, GuideStep.setup);
    expect(find.text('5–6 ft'), findsOneWidget);
  });

  testWidgets('pose-front carries the 45° arm label', (tester) async {
    await pumpStep(tester, GuideStep.poseFront);
    expect(find.text('45°'), findsOneWidget);
  });

  testWidgets('pose-side is pure vector — no diagram text', (tester) async {
    await pumpStep(tester, GuideStep.poseSide);
    expect(find.text('45°'), findsNothing);
    expect(find.text('Your height'), findsNothing);
  });
}
