import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders the canonical line and CTA per kind', (
      tester,
    ) async {
      await tester.pumpApp(
        const SingleChildScrollView(
          child: EmptyState(kind: EmptyStateKind.feed),
        ),
      );
      expect(
        find.text('Follow designers to fill your feed'),
        findsOneWidget,
      );
      expect(find.text('Explore outfits'), findsOneWidget);

      await tester.pumpApp(
        const SingleChildScrollView(
          child: EmptyState(kind: EmptyStateKind.orders),
        ),
      );
      expect(find.text('No orders yet'), findsOneWidget);
      expect(find.text('Discover designers'), findsOneWidget);
    });

    testWidgets('CTA fires onCta', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        SingleChildScrollView(
          child: EmptyState(kind: EmptyStateKind.vault, onCta: () => taps++),
        ),
      );

      await tester.tap(find.text('Take measurement'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(taps, 1);
    });

    testWidgets('camera-permission carries the manual-entry escape hatch', (
      tester,
    ) async {
      var secondary = 0;
      await tester.pumpApp(
        SingleChildScrollView(
          child: EmptyState(
            kind: EmptyStateKind.cameraPermission,
            onSecondaryCta: () => secondary++,
          ),
        ),
      );

      await tester.tap(find.text('Enter manually instead'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(secondary, 1);
    });
  });
}
