import 'package:apparule/src/core/ui/transaction_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('TransactionRow', () {
    testWidgets('credits read +, debits keep the − from formatNaira', (
      tester,
    ) async {
      await tester.pumpApp(
        const Column(
          children: <Widget>[
            TransactionRow(
              kind: TransactionKind.escrowHeld,
              amountCents: 4500000,
              orderNumber: '#APR-1042',
              providerRef: 'PSK-9841377',
              dateLabel: 'Jul 12',
            ),
            TransactionRow(
              kind: TransactionKind.payout,
              amountCents: -5580000,
              label: 'Payout to GTBank ••• 4521',
              providerRef: 'PSK-9921404',
              dateLabel: 'Jul 16',
            ),
            TransactionRow(
              kind: TransactionKind.feeLine,
              amountCents: -620000,
              orderNumber: '#APR-1058',
            ),
          ],
        ),
      );

      // Derived label for the escrow row; free-text override for the
      // canvas payout row; the fee line derives its 10% label.
      expect(find.text('Escrow held · #APR-1042'), findsOneWidget);
      expect(find.text('+₦45,000'), findsOneWidget);
      expect(find.text('PSK-9841377 · Jul 12'), findsOneWidget);

      expect(find.text('Payout to GTBank ••• 4521'), findsOneWidget);
      expect(find.text('−₦55,800'), findsOneWidget);

      expect(find.text('Platform fee (10%) · #APR-1058'), findsOneWidget);
      expect(find.text('−₦6,200'), findsOneWidget);
    });
  });
}
