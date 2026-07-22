import 'package:apparule/src/core/ui/capture_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('CaptureOptionCard', () {
    testWidgets('webcam-upload carries the canonical camera copy', (
      tester,
    ) async {
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 340,
            child: CaptureOptionCard(
              mode: CaptureOptionMode.webcamUpload,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Use your camera'), findsOneWidget);
      expect(
        find.text('Full-body photo, we measure automatically'),
        findsOneWidget,
      );
    });

    testWidgets('manual-entry carries the tape-measure copy and taps', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 340,
            child: CaptureOptionCard(
              mode: CaptureOptionMode.manualEntry,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('Enter manually'), findsOneWidget);
      expect(find.text('Tape-measure your key metrics'), findsOneWidget);

      await tester.tap(find.byType(CaptureOptionCard));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
