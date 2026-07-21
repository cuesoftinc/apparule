import 'package:apparule/src/core/ui/countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Countdown renders m:ss from the animation value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countdown(animation: AlwaysStoppedAnimation<int>(65)),
      ),
    );
    expect(find.text('1:05'), findsOneWidget);
  });

  testWidgets('Countdown pads single-digit seconds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countdown(animation: AlwaysStoppedAnimation<int>(3)),
      ),
    );
    expect(find.text('0:03'), findsOneWidget);
  });
}
