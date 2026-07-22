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

    testWidgets('sub titles center on the BAR, not the leftover flow space '
        '(centered-title ruling)', (tester) async {
      // Back present, no trailing — the old in-flow layout grew the title
      // into the hidden-trailing space and skewed it right.
      await tester.pumpApp(
        Scaffold(
          appBar: AppTopBar(
            kind: AppTopBarKind.sub,
            title: 'Vault',
            onBack: () {},
          ),
        ),
      );

      final barCenter = tester.getCenter(find.byType(AppTopBar)).dx;
      final titleCenter = tester.getCenter(find.text('Vault')).dx;
      expect(titleCenter, moreOrLessEquals(barCenter, epsilon: 1));
    });

    testWidgets('a long sub title pads by the max slot width — symmetric '
        'and clear of both slots', (tester) async {
      await tester.pumpApp(
        Scaffold(
          appBar: AppTopBar(
            kind: AppTopBarKind.sub,
            title: 'Ankara maxi skirt with structured waistband and train',
            onBack: () {},
          ),
        ),
      );

      final bar = tester.getRect(find.byType(AppTopBar));
      final title = tester.getRect(
        find.text('Ankara maxi skirt with structured waistband and train'),
      );
      final back = tester.getRect(find.bySemanticsLabel('Back'));

      // Still truly centered…
      expect(
        title.center.dx,
        moreOrLessEquals(bar.center.dx, epsilon: 1),
      );
      // …and clear of the leading slot (padding = max slot width keeps
      // the ellipsis symmetric instead of running under a slot).
      expect(title.left, greaterThanOrEqualTo(back.right - 1));
    });
  });
}
