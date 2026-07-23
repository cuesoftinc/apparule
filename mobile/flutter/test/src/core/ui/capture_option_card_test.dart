import 'package:apparule/src/core/ui/capture_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('CaptureOptionCard', () {
    testWidgets('photo-upload carries the two-photo camera copy (M-10 + '
        'the M-12 axis rename)', (tester) async {
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 340,
            child: CaptureOptionCard(
              mode: CaptureOptionMode.photoUpload,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Use your camera'), findsOneWidget);
      expect(
        find.text('Two photos — we measure automatically'),
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
