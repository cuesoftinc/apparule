import 'package:apparule/src/core/ui/earnings_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('EarningsSummary', () {
    testWidgets('renders both balance cards with formatted naira', (
      tester,
    ) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 390,
            child: EarningsSummary(
              balanceCents: 24300000,
              pendingCents: 4050000,
            ),
          ),
        ),
      );

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('In escrow'), findsOneWidget);
      expect(find.text('₦243,000'), findsOneWidget);
      expect(find.text('₦40,500'), findsOneWidget);
    });
  });
}
