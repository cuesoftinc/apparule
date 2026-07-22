import 'package:apparule/src/core/ui/tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppTabBar', () {
    testWidgets('tapping a tab reports it through onSelect', (tester) async {
      final selected = <AppTab>[];
      await tester.pumpApp(
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppTabBar(active: AppTab.home, onSelect: selected.add),
          ],
        ),
      );

      for (final tab in AppTab.values) {
        await tester.tap(find.bySemanticsLabel(tab.semanticLabel));
        await tester.pump();
      }

      expect(selected, AppTab.values);
    });

    testWidgets('orders badge renders the count (MI-16)', (tester) async {
      await tester.pumpApp(
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppTabBar(
              active: AppTab.home,
              ordersBadge: 3,
              onSelect: (_) {},
            ),
          ],
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('badge none renders no count text', (tester) async {
      await tester.pumpApp(
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppTabBar(active: AppTab.home, onSelect: (_) {}),
          ],
        ),
      );

      expect(find.text('0'), findsNothing);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('large badge counts compact (formatCount)', (tester) async {
      await tester.pumpApp(
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppTabBar(
              active: AppTab.orders,
              ordersBadge: 1200,
              onSelect: (_) {},
            ),
          ],
        ),
      );

      expect(find.text('1.2k'), findsOneWidget);
    });
  });
}
