import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/notched.dart';

/// C9 designer public profile: the B6 header off the graph, the MI-7
/// morph with the unfollow confirm, the published grid.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Future<void> pump(WidgetTester tester, String username) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpApp(
      PublicProfileScreen(username: username),
      postRepository: PostRepositoryFake(now: () => pinned),
      overrides: <Override>[
        clockProvider.overrideWith(
          (ref) =>
              () => pinned,
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the B6 designer header: story ring, graph '
      'counts, bio, grid', (tester) async {
    await pump(tester, 'amara.designs');

    expect(find.text('amara.designs'), findsWidgets);
    expect(find.text('Amara Designs · Lagos'), findsOneWidget);
    expect(
      find.text(
        'Ankara & contemporary tailoring. Lagos. '
        'Made-to-measure only.',
      ),
      findsOneWidget,
    );
    // Graph-derived counts: 3 posts · 8 followers · 2 following.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    // Story-ring construction on designer headers (B6).
    final avatar = tester.widget<Avatar>(find.byType(Avatar).first);
    expect(avatar.ring, AvatarRing.gradient);
    // The published grid renders beneath.
    expect(find.byType(Image), findsNWidgets(3));
    // kiki follows amara → quiet Following + the request CTA.
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Request an outfit'), findsOneWidget);
  });

  testWidgets('MI-7: Follow morphs to Following through the graph', (
    tester,
  ) async {
    await pump(tester, 'tunde.o');

    expect(find.text('Follow'), findsOneWidget);
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();

    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Follow'), findsNothing);
  });

  testWidgets('unfollow is never a blind toggle — the confirm sheet '
      'gates it', (tester) async {
    await pump(tester, 'amara.designs');

    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    expect(find.text('Unfollow?'), findsOneWidget);
    expect(
      find.text('Their new outfits will stop showing in your feed.'),
      findsOneWidget,
    );

    // Cancel leaves the graph untouched.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Following'), findsOneWidget);

    // Confirm morphs back to the gradient Follow.
    await tester.tap(find.text('Following'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unfollow @amara.designs'));
    await tester.pumpAndSettle();
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('a regular account renders the private-vault variant', (
    tester,
  ) async {
    await pump(tester, 'zainab.k');

    expect(find.text('Zainab Kassim'), findsOneWidget);
    expect(
      find.text('Measurements are private — shared only inside a request.'),
      findsOneWidget,
    );
    expect(find.text('Follow'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an unknown username renders the not-found state', (
    tester,
  ) async {
    await pump(tester, 'nobody.here');

    expect(
      find.text("@nobody.here doesn't exist (or isn't visible)."),
      findsOneWidget,
    );
  });

  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await pump(tester, 'amara.designs');
    expectNoContentInTopInset(tester);
  });
}
