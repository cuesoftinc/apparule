import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppTopBar', () {
    testWidgets('root paints the title with no back control', (tester) async {
      await tester.pumpApp(
        const Scaffold(appBar: AppTopBar(title: 'Apparule')),
      );

      expect(find.text('Apparule'), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsNothing);
    });

    testWidgets('sub kind shows the named back control and fires onBack', (
      tester,
    ) async {
      var backs = 0;
      await tester.pumpApp(
        Scaffold(
          appBar: AppTopBar(
            kind: AppTopBarKind.sub,
            title: 'Order #A2041',
            onBack: () => backs++,
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();

      expect(backs, 1);
      expect(find.text('Order #A2041'), findsOneWidget);
    });

    testWidgets('trailing slot renders', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          appBar: AppTopBar(
            title: 'Apparule',
            trailing: Icon(Icons.notifications_none),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('preferred size is the 56px chrome row', (tester) async {
      const bar = AppTopBar(title: 'Apparule');
      expect(bar.preferredSize.height, 56);
    });
  });
}
