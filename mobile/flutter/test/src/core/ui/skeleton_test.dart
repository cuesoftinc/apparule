import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('Skeleton', () {
    for (final kind in SkeletonKind.values) {
      testWidgets('kind ${kind.name} shimmers without throwing', (
        tester,
      ) async {
        await tester.pumpApp(
          SingleChildScrollView(
            child: SizedBox(width: 280, child: Skeleton(kind: kind)),
          ),
        );
        // MI-19 shimmer repeats — pump fixed frames, never settle.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.byType(Skeleton), findsOneWidget);
      });
    }
  });
}
