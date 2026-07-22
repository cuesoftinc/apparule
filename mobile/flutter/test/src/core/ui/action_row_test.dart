import 'package:apparule/src/core/ui/action_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('ActionRow', () {
    Widget row({
      bool liked = false,
      bool saved = false,
      VoidCallback? onToggleLike,
      VoidCallback? onToggleSave,
      VoidCallback? onComment,
      VoidCallback? onShare,
    }) {
      return SizedBox(
        width: 390,
        child: ActionRow(
          liked: liked,
          saved: saved,
          likeCount: 128,
          onToggleLike: onToggleLike ?? () {},
          onToggleSave: onToggleSave ?? () {},
          onComment: onComment,
          onShare: onShare,
        ),
      );
    }

    testWidgets('icon-only controls carry semantics labels', (tester) async {
      await tester.pumpApp(row());

      expect(find.bySemanticsLabel('Like'), findsOneWidget);
      expect(find.bySemanticsLabel('Comments'), findsOneWidget);
      expect(find.bySemanticsLabel('Share'), findsOneWidget);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });

    testWidgets('labels flip with liked/saved state', (tester) async {
      await tester.pumpApp(row(liked: true, saved: true));

      expect(find.bySemanticsLabel('Unlike'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove from saved'), findsOneWidget);
    });

    testWidgets('taps fire the callbacks', (tester) async {
      var likes = 0;
      var saves = 0;
      var comments = 0;
      var shares = 0;
      await tester.pumpApp(
        row(
          onToggleLike: () => likes++,
          onToggleSave: () => saves++,
          onComment: () => comments++,
          onShare: () => shares++,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Like'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Comments'));
      await tester.tap(find.bySemanticsLabel('Share'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(likes, 1);
      expect(saves, 1);
      expect(comments, 1);
      expect(shares, 1);
    });
  });
}
