import 'package:apparule/src/app/boot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/notched.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('BootScreen', () {
    testWidgets('renders the gradient wordmark with no spinner at first '
        'frame', (tester) async {
      await tester.pumpApp(const BootScreen());

      expect(find.text('Apparule'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('admits the spinner only past kBootSpinnerDelay', (
      tester,
    ) async {
      await tester.pumpApp(const BootScreen());
      await tester.pump(kBootSpinnerDelay - const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('keeps content clear of display-cutout insets', (
      tester,
    ) async {
      applyNotchedView(tester);
      await tester.pumpApp(const BootScreen());
      await expectContentClearOfTopInsets(tester);
    });
  });
}
