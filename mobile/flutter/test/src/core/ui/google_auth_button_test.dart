import 'package:apparule/src/core/ui/google_auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('GoogleAuthButton', () {
    testWidgets('loading swaps the label for a spinner and disables', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: GoogleAuthButton(
            label: 'Continue with Google',
            loading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Continue with Google'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );

      await tester.tap(find.byType(GoogleAuthButton));
      await tester.pump(const Duration(milliseconds: 50));
      expect(taps, 0);
    });
  });
}
