import 'package:apparule/src/core/ui/processing_constellation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('ProcessingConstellation', () {
    Future<void> pumpState(
      WidgetTester tester,
      ProcessingState state,
    ) async {
      await tester.pumpApp(
        SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 240,
              child: ProcessingConstellation(state: state),
            ),
          ),
        ),
      );
      // Landmarks pulse while processing — fixed frame, never settle.
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('processing shows the measuring line', (tester) async {
      await pumpState(tester, ProcessingState.processing);
      expect(find.text('Measuring…'), findsOneWidget);
    });

    testWidgets('success shows Done', (tester) async {
      await pumpState(tester, ProcessingState.success);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('failed shows the retake line', (tester) async {
      await pumpState(tester, ProcessingState.failed);
      expect(find.text("Couldn't measure — retake"), findsOneWidget);
    });
  });
}
