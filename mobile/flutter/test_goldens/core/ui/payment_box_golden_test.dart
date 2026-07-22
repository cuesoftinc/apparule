import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/payment_box.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// PaymentBox (Figma 90:1103) — `state` ×6 × `role` ×2 (+ the MI-15
/// escrow explainer), both themes. The paying cell hosts a spinner, so
/// the suite pumps a fixed frame.
void main() {
  themedGoldenTest(
    'PaymentBox matrix',
    fileName: 'payment_box',
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        for (final state in PaymentBoxState.values)
          for (final role in PaymentRole.values)
            GoldenTestScenario(
              name: '${state.name} · ${role.name}',
              child: SizedBox(
                width: 360,
                child: PaymentBox(
                  state: state,
                  role: role,
                  quoteCents: 4500000,
                  onPay: () {},
                  onAction: (_) {},
                ),
              ),
            ),
        GoldenTestScenario(
          name: 'escrow-held · customer · explainer (MI-15)',
          child: const SizedBox(
            width: 360,
            child: PaymentBox(
              state: PaymentBoxState.escrowHeld,
              role: PaymentRole.customer,
              quoteCents: 4500000,
              showEscrowExplainer: true,
            ),
          ),
        ),
      ],
    ),
  );
}
