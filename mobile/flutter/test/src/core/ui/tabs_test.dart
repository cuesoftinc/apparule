import 'package:apparule/src/core/ui/tabs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppTabs', () {
    testWidgets('text kind renders both labels and reports selection', (
      tester,
    ) async {
      AppTabsActive? selected;
      await tester.pumpApp(
        AppTabs(
          first: const AppTabItem.text('4.2k followers'),
          second: const AppTabItem.text('310 following'),
          active: AppTabsActive.first,
          onSelect: (tab) => selected = tab,
        ),
      );

      expect(find.text('4.2k followers'), findsOneWidget);
      expect(find.text('310 following'), findsOneWidget);

      await tester.tap(find.text('310 following'));
      expect(selected, AppTabsActive.second);
    });

    testWidgets('icon kind carries semantic labels for both cells', (
      tester,
    ) async {
      await tester.pumpApp(
        AppTabs(
          first: const AppTabItem.icon(
            LucideIcons.grid3X3,
            semanticLabel: 'Posts',
          ),
          second: const AppTabItem.icon(
            LucideIcons.bookmark,
            semanticLabel: 'Saved looks',
          ),
          active: AppTabsActive.second,
          onSelect: (_) {},
        ),
      );

      expect(find.byIcon(LucideIcons.grid3X3), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);
      expect(find.bySemanticsLabel('Posts'), findsOneWidget);
      expect(find.bySemanticsLabel('Saved looks'), findsOneWidget);
    });
  });
}
