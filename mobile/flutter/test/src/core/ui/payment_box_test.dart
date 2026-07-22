import 'package:apparule/src/core/ui/payment_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('PaymentBox', () {
    Widget box({
      required PaymentBoxState state,
      required PaymentRole role,
      bool showEscrowExplainer = false,
      VoidCallback? onPay,
      ValueChanged<String>? onAction,
    }) {
      return SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: PaymentBox(
            state: state,
            role: role,
            quoteCents: 4500000,
            showEscrowExplainer: showEscrowExplainer,
            onPay: onPay,
            onAction: onAction,
          ),
        ),
      );
    }

    testWidgets('quoted × customer itemizes the fee and pays', (
      tester,
    ) async {
      var pays = 0;
      await tester.pumpApp(
        box(
          state: PaymentBoxState.quoted,
          role: PaymentRole.customer,
          onPay: () => pays++,
        ),
      );

      expect(find.text('Quote · ₦45,000'), findsOneWidget);
      expect(
        find.text('Includes 10% platform fee · ₦4,500'),
        findsOneWidget,
      );

      await tester.tap(find.text('Pay ₦45,000'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(pays, 1);
    });

    testWidgets('quoted × designer shows the net line and edit CTA', (
      tester,
    ) async {
      final actions = <String>[];
      await tester.pumpApp(
        box(
          state: PaymentBoxState.quoted,
          role: PaymentRole.designer,
          onAction: actions.add,
        ),
      );

      expect(
        find.text('You receive ₦40,500 after the 10% platform fee'),
        findsOneWidget,
      );

      await tester.tap(find.text('Edit quote'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(actions, <String>['Edit quote']);
    });

    testWidgets('dispute-frozen CTA label follows the role', (tester) async {
      await tester.pumpApp(
        box(
          state: PaymentBoxState.disputeFrozen,
          role: PaymentRole.customer,
        ),
      );
      expect(find.text('View dispute'), findsOneWidget);

      await tester.pumpApp(
        box(
          state: PaymentBoxState.disputeFrozen,
          role: PaymentRole.designer,
        ),
      );
      expect(find.text('Respond to dispute'), findsOneWidget);
    });

    testWidgets('escrow explainer expands on first payment (MI-15)', (
      tester,
    ) async {
      await tester.pumpApp(
        box(
          state: PaymentBoxState.escrowHeld,
          role: PaymentRole.customer,
          showEscrowExplainer: true,
        ),
      );

      expect(find.text('₦45,000 held in escrow'), findsOneWidget);
      expect(
        find.textContaining('Your money stays with Apparule'),
        findsOneWidget,
      );
    });
  });
}
