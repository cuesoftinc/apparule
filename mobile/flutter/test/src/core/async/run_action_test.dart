import 'dart:async';

import 'package:apparule/src/core/async/run_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// runAction (CLASS 4 lock): await → catch → rollback → toast; the caller
/// keeps the user's input and learns success/failure from the returned
/// bool. Exceptions AND Errors (the fakes' StateError lifecycle guards)
/// both land in the toast path — nothing escapes into the zone.
void main() {
  Future<BuildContext> host(WidgetTester tester) async {
    await tester.pumpApp(const Scaffold(body: SizedBox.shrink()));
    return tester.element(find.byType(SizedBox));
  }

  testWidgets('success: resolves true, no rollback, no toast', //
  (tester) async {
    final context = await host(tester);
    var rolledBack = false;

    final ok = await runAction(
      context,
      () async {},
      rollback: () => rolledBack = true,
    );
    await tester.pump();

    expect(ok, isTrue);
    expect(rolledBack, isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Exception: rolls back, toasts the shared copy, resolves '
      'false', (tester) async {
    final context = await host(tester);
    var rolledBack = false;

    final ok = await runAction(
      context,
      () async => throw Exception('network'),
      rollback: () => rolledBack = true,
    );
    await tester.pump();

    expect(ok, isFalse);
    expect(rolledBack, isTrue);
    expect(find.text('Something went wrong — try again.'), findsOneWidget);
  });

  testWidgets('StateError (the fakes\' illegal-transition guard) is '
      'caught and toasted too', (tester) async {
    final context = await host(tester);

    final ok = await runAction(
      context,
      () async => throw StateError('pay: not quoted'),
    );
    await tester.pump();

    expect(ok, isFalse);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('failureText overrides the default toast copy', //
  (tester) async {
    final context = await host(tester);

    await runAction(
      context,
      () async => throw Exception('boom'),
      failureText: 'Session deleted failed',
    );
    await tester.pump();

    expect(find.text('Session deleted failed'), findsOneWidget);
    expect(find.text('Something went wrong — try again.'), findsNothing);
  });

  testWidgets('failure resolves only after the pending future fails — '
      'input cleared on success alone stays intact', (tester) async {
    final context = await host(tester);
    final gate = Completer<void>();
    final input = TextEditingController(text: 'draft comment');
    addTearDown(input.dispose);

    var settled = false;
    final pending = runAction(context, () => gate.future).then((ok) {
      settled = true;
      // The runAction contract: clear input ONLY when ok.
      if (ok) input.clear();
      return ok;
    });
    await tester.pump();
    expect(settled, isFalse);

    gate.completeError(Exception('server 500'));
    expect(await pending, isFalse);
    await tester.pump();

    // The user's text survived the failure (CLASS 4: input preserved).
    expect(input.text, 'draft comment');
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
