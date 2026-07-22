import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/transaction_row.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// TransactionRow (Figma 97:1281 masters) — kind payout / escrow-held /
/// fee-line, canvas free-text override, both themes.
void main() {
  themedGoldenTest(
    'TransactionRow',
    fileName: 'transaction_row',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'payout (canvas label)',
          child: const SizedBox(
            width: 390,
            child: TransactionRow(
              kind: TransactionKind.payout,
              amountCents: -5580000,
              label: 'Payout to GTBank ••• 4521',
              providerRef: 'PSK-9921404',
              dateLabel: 'Jul 16',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'escrow held (credit)',
          child: const SizedBox(
            width: 390,
            child: TransactionRow(
              kind: TransactionKind.escrowHeld,
              amountCents: 4500000,
              orderNumber: '#APR-1042',
              providerRef: 'PSK-9841377',
              dateLabel: 'Jul 12',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'fee line (10%)',
          child: const SizedBox(
            width: 390,
            child: TransactionRow(
              kind: TransactionKind.feeLine,
              amountCents: -620000,
              orderNumber: '#APR-1058',
              providerRef: 'PSK-9987201',
              dateLabel: 'Jul 16',
            ),
          ),
        ),
      ],
    ),
  );
}
