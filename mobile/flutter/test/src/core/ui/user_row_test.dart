import 'package:apparule/src/core/ui/user_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('UserRow', () {
    testWidgets('renders username + meta and routes the MI-7 trailing '
        'taps distinctly', (tester) async {
      var followed = 0;
      var followingTapped = 0;
      var opened = 0;
      await tester.pumpApp(
        Column(
          children: <Widget>[
            UserRow(
              username: 'amara.designs',
              meta: 'Amara Okafor · designer',
              verified: true,
              trailing: UserRowTrailing.following,
              onTap: () => opened++,
              onFollow: () => followed++,
              onFollowingTap: () => followingTapped++,
            ),
            UserRow(
              username: 'tunde.o',
              meta: 'Tunde Okonkwo · designer',
              trailing: UserRowTrailing.follow,
              onFollow: () => followed++,
            ),
            const UserRow(username: 'ada.eze', meta: 'Ada Eze'),
          ],
        ),
      );

      expect(find.text('amara.designs'), findsOneWidget);
      expect(find.text('Amara Okafor · designer'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);

      // `none` renders no trailing control at all.
      expect(find.text('ada.eze'), findsOneWidget);

      await tester.tap(find.text('Following'));
      expect(followingTapped, 1);
      expect(followed, 0);

      await tester.tap(find.text('Follow'));
      expect(followed, 1);

      await tester.tap(find.text('amara.designs'));
      expect(opened, 1);
    });

    group('prop-contract (CLASS 3): null handler ⇒ no control', () {
      testWidgets(
        'a trailing axis without its handler renders no '
        'button (a Follow that cannot follow is a dead affordance)', //
        (tester) async {
          await tester.pumpApp(
            const Column(
              children: <Widget>[
                UserRow(username: 'tunde.o', trailing: UserRowTrailing.follow),
                UserRow(
                  username: 'amara.designs',
                  trailing: UserRowTrailing.following,
                ),
              ],
            ),
          );

          expect(find.text('Follow'), findsNothing);
          expect(find.text('Following'), findsNothing);
        },
      );
    });
  });
}
