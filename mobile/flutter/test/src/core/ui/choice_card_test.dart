import 'package:apparule/src/core/ui/choice_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('ChoiceCard (create chooser card language, 548:2750/2759)', () {
    testWidgets('renders icon, title, subtitle and taps', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 358,
            child: ChoiceCard(
              icon: LucideIcons.camera,
              title: 'Take measurements',
              subtitle: 'Two photos — about a minute',
              primary: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('Take measurements'), findsOneWidget);
      expect(find.text('Two photos — about a minute'), findsOneWidget);
      expect(find.byIcon(LucideIcons.camera), findsOneWidget);

      await tester.tap(find.byType(ChoiceCard));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('primary carries the 1.5px accent border; secondary the '
        '1px border stroke', (tester) async {
      await tester.pumpApp(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 358,
                child: ChoiceCard(
                  icon: LucideIcons.camera,
                  title: 'Primary',
                  subtitle: 'meta',
                  primary: true,
                  onTap: () {},
                ),
              ),
              SizedBox(
                width: 358,
                child: ChoiceCard(
                  icon: LucideIcons.shirt,
                  title: 'Secondary',
                  subtitle: 'meta',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      );

      BoxBorder borderOf(String title) =>
          (tester
                      .widget<Container>(
                        find.ancestor(
                          of: find.text(title),
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .border!;

      expect((borderOf('Primary') as Border).top.width, 1.5);
      expect((borderOf('Secondary') as Border).top.width, 1);
    });

    testWidgets('exposes one named button node (title + subtitle)', (
      tester,
    ) async {
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 358,
            child: ChoiceCard(
              icon: LucideIcons.shirt,
              title: 'Post an outfit',
              subtitle: 'Become a designer to post',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Post an outfit. Become a designer to post'),
        findsOneWidget,
      );
    });
  });
}
