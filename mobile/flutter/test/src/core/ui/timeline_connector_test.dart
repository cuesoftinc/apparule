import 'package:apparule/src/core/ui/timeline_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// TimelineConnector (MI-14): the connector draws over 400ms on mount,
/// the current dot pulses, terminal errors get their own rung, and the
/// last row drops the connector.
void main() {
  Widget host(TimelineDotState state, {bool last = false}) => SizedBox(
    height: 80,
    child: TimelineConnector(state: state, last: last),
  );

  Finder connector() => find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is ConnectorDrawPainter,
  );

  double drawProgressOf(WidgetTester tester) =>
      (tester.widget<CustomPaint>(connector()).painter! as ConnectorDrawPainter)
          .progress;

  testWidgets('the connector draws 0→full over 400ms', (tester) async {
    await tester.pumpApp(host(TimelineDotState.done));
    expect(drawProgressOf(tester), 0);

    await tester.pump(const Duration(milliseconds: 200));
    final mid = drawProgressOf(tester);
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));

    await tester.pump(const Duration(milliseconds: 250));
    expect(drawProgressOf(tester), 1);
  });

  testWidgets('the connector survives an IntrinsicHeight row mid-draw '
      '(the C8 timeline geometry — a fractional sizer at factor 0 '
      'reports an infinite intrinsic and crashes)', (tester) async {
    await tester.pumpApp(
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const TimelineConnector(state: TimelineDotState.done),
            SizedBox(width: 40, height: 80, child: Container()),
          ],
        ),
      ),
    );
    // Frame one: draw progress 0 — the layout must hold.
    expect(tester.takeException(), isNull);
    expect(drawProgressOf(tester), 0);
    await tester.pump(const Duration(milliseconds: 450));
    expect(drawProgressOf(tester), 1);
  });

  testWidgets('the last row renders no connector', (tester) async {
    await tester.pumpApp(host(TimelineDotState.done, last: true));
    await tester.pump(const Duration(milliseconds: 450));
    expect(connector(), findsNothing);
  });

  testWidgets(
    'the current dot pulses; the others rest still', //
    (tester) async {
      await tester.pumpApp(host(TimelineDotState.current, last: true));
      await tester.pump(const Duration(milliseconds: 600));
      final pulsing = tester
          .widget<ScaleTransition>(find.byType(ScaleTransition))
          .scale
          .value;
      expect(pulsing, greaterThan(1));

      await tester.pumpApp(host(TimelineDotState.done, last: true));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(ScaleTransition), findsNothing);
    },
  );

  testWidgets('every rung renders its dot — terminal error included '
      '(D41: no green ✓ on a dispute)', (tester) async {
    for (final state in TimelineDotState.values) {
      await tester.pumpApp(host(state, last: true));
      await tester.pump(const Duration(milliseconds: 450));
      expect(
        find.byType(TimelineConnector),
        findsOneWidget,
        reason: '$state must render',
      );
    }
  });
}
