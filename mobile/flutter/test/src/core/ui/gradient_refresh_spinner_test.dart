import 'dart:async';

import 'package:apparule/src/core/ui/edge_resist_physics.dart';
import 'package:apparule/src/core/ui/gradient_refresh_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// GradientRefreshSpinner (MI-5): the arc grows with the pull, a release
/// at/past 72px fires the haptic + onRefresh, and the spinner rotates
/// until the refresh settles. Sub-threshold pulls never trigger.
void main() {
  late List<MethodCall> haptics;

  setUp(() {
    haptics = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget host({
    required Future<void> Function() onRefresh,
  }) => Scaffold(
    body: GradientRefreshSpinner(
      onRefresh: onRefresh,
      child: ListView(
        physics: const EdgeResistPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: const <Widget>[SizedBox(height: 40, child: Text('row'))],
      ),
    ),
  );

  testWidgets('a past-threshold pull triggers on release: haptic + '
      'onRefresh + spinner until settled', (tester) async {
    final gate = Completer<void>();
    var refreshes = 0;
    await tester.pumpApp(
      host(
        onRefresh: () {
          refreshes++;
          return gate.future;
        },
      ),
    );

    // Bouncing physics applies friction to overscroll — walk the gesture
    // far enough that the resisted pull still crosses the 72px threshold.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    for (var move = 0; move < 10; move++) {
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
    }
    await gesture.up();
    // The release trigger rides the first ballistic notification — give
    // the spring-back a few frames.
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(refreshes, 1);
    expect(haptics, hasLength(1)); // MI-5 haptic on trigger
    expect(find.byType(GradientSpinnerIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(GradientSpinnerIndicator), findsNothing);
  });

  testWidgets('a sub-threshold pull springs back without triggering', //
  (tester) async {
    var refreshes = 0;
    await tester.pumpApp(
      host(
        onRefresh: () async {
          refreshes++;
        },
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, 40));
    await tester.pumpAndSettle();

    expect(refreshes, 0);
    expect(haptics, isEmpty);
    expect(find.byType(GradientSpinnerIndicator), findsNothing);
  });

  testWidgets('the indicator grows with the pull before the threshold', //
  (tester) async {
    await tester.pumpApp(host(onRefresh: () async {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 48));
    await tester.pump();

    final indicator = tester.widget<GradientSpinnerIndicator>(
      find.byType(GradientSpinnerIndicator),
    );
    expect(indicator.progress, greaterThan(0));
    expect(indicator.progress, lessThan(1));
    expect(indicator.spinning, isFalse);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(GradientSpinnerIndicator), findsNothing);
  });
}
