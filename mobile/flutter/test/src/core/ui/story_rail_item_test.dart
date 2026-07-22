import 'package:apparule/src/core/ui/story_rail_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('StoryRailItem', () {
    testWidgets('renders the username and fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Center(
          child: StoryRailItem(
            username: 'eniola.stitches',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.text('eniola.stitches'), findsOneWidget);

      await tester.tap(find.byType(StoryRailItem));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('loading state renders the rotating ring (MI-8)', (
      tester,
    ) async {
      await tester.pumpApp(
        const Center(
          child: StoryRailItem(
            username: 'eniola.stitches',
            state: StoryRailItemState.loading,
          ),
        ),
      );
      // The ring repeats — pump a fixed frame, never settle.
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(StoryRailItem), findsOneWidget);
    });
  });
}
