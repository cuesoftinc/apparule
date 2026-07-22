import 'package:apparule/src/core/ui/capture_overlay.dart';
import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('CaptureOverlay', () {
    Future<void> pumpGuide(
      WidgetTester tester,
      CaptureOverlay overlay,
    ) async {
      await tester.pumpApp(
        SingleChildScrollView(
          child: Center(child: SizedBox(width: 270, child: overlay)),
        ),
      );
      // The searching silhouette pulses — fixed frame, never settle.
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('searching shows the outline instruction', (tester) async {
      await pumpGuide(
        tester,
        const CaptureOverlay(guide: CaptureGuide.searching),
      );
      expect(find.text('Stand inside the outline'), findsOneWidget);
    });

    testWidgets('aligned flips the copy to hold-still', (tester) async {
      await pumpGuide(
        tester,
        const CaptureOverlay(guide: CaptureGuide.aligned),
      );
      expect(find.text('Perfect — hold still'), findsOneWidget);
    });

    testWidgets('countdown guide hosts the CountdownRing', (tester) async {
      await pumpGuide(
        tester,
        const CaptureOverlay(
          guide: CaptureGuide.countdown,
          countdown: CountdownCount.two,
        ),
      );
      expect(find.byType(CountdownRing), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('qc-hint guide surfaces exactly one chip', (tester) async {
      await pumpGuide(
        tester,
        const CaptureOverlay(
          guide: CaptureGuide.qcHint,
          qcCode: QcFailCode.tooFar,
        ),
      );
      expect(find.byType(QCHintChip), findsOneWidget);
      expect(
        find.text('Move closer — fill more of the frame'),
        findsOneWidget,
      );
    });
  });
}
