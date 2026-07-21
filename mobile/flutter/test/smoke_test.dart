import 'package:apparule/main.dart';
import 'package:apparule/src/app/splash_screen.dart';
import 'package:apparule/src/services/persistence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('boot smoke: main()\'s MaterialApp builds to the splash screen', (
    tester,
  ) async {
    // Mirror main(): SharedPreferences is loaded before runApp.
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await Persistence.initPersistence();

    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // The legacy splash schedules a 3s navigation Timer it never cancels;
    // flush it (and the resulting route transition) so the test ends with
    // no pending timers.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // The navigation target is the legacy HomeScreen — REWRITE-registered
    // (mobile-implementation.md §11) and still painting `apparule.png`, an
    // asset quarantined to assets/legacy/ (unbundled) in the toolchain-floor
    // wave. Tolerate exactly that documented missing-asset report (and
    // nothing else) until the C1 rewrite replaces the screen.
    final Object? exception = tester.takeException();
    if (exception != null) {
      expect('$exception', contains('apparule.png'));
    }
  });
}
