import 'dart:typed_data';

import 'package:apparule/src/core/ui/post_card.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// Deterministic 1×1 gray PNG — media stand-in.
final ImageProvider<Object> _pixel = MemoryImage(
  Uint8List.fromList(const <int>[
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xde, 0x00, 0x00, 0x00,
    0x0c, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0xe8, 0xe8, 0xe8, 0x00,
    0x00, 0x03, 0x34, 0x01, 0x99, 0xc1, 0xac, 0xc0, 0xb1, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
  ]),
);

void main() {
  group('PostCard', () {
    Widget card({
      bool liked = false,
      int mediaCount = 1,
      String caption = 'Ankara two-piece.',
      int commentCount = 0,
      VoidCallback? onToggleLike,
      VoidCallback? onComment,
      VoidCallback? onRequest,
      VoidCallback? onProfileTap,
    }) {
      return SingleChildScrollView(
        child: SizedBox(
          width: 390,
          child: PostCard(
            username: 'eniola.stitches',
            media: List<ImageProvider<Object>>.filled(mediaCount, _pixel),
            liked: liked,
            saved: false,
            likeCount: 1204,
            commentCount: commentCount,
            caption: caption,
            timestampLabel: '2h',
            onToggleLike: onToggleLike,
            onToggleSave: () {},
            onComment: onComment,
            onRequest: onRequest,
            onProfileTap: onProfileTap,
          ),
        ),
      );
    }

    Future<void> doubleTapMedia(WidgetTester tester) async {
      final media = find.byType(AspectRatio).first;
      await tester.tap(media);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(media);
      // Let the MI-1 big-heart timer (700ms) expire before the test ends.
      await tester.pump(const Duration(milliseconds: 800));
    }

    testWidgets('double-tap on media likes when not yet liked (MI-1)', (
      tester,
    ) async {
      var likes = 0;
      await tester.pumpApp(card(onToggleLike: () => likes++));

      await doubleTapMedia(tester);

      expect(likes, 1);
    });

    testWidgets('double-tap does not unlike an already-liked post', (
      tester,
    ) async {
      var likes = 0;
      await tester.pumpApp(card(liked: true, onToggleLike: () => likes++));

      await doubleTapMedia(tester);

      expect(likes, 0);
    });

    testWidgets('comments line fires onComment', (tester) async {
      var comments = 0;
      await tester.pumpApp(
        card(commentCount: 5, onComment: () => comments++),
      );

      await tester.ensureVisible(find.text('View all 5 comments'));
      await tester.tap(find.text('View all 5 comments'));
      await tester.pump();

      expect(comments, 1);
    });

    testWidgets('a caption over 80 chars shows "more" and expands on tap', (
      tester,
    ) async {
      const caption =
          'Ankara two-piece with a hand-beaded neckline, tailored to the '
          'vault measurements and finished with a matching gele for the '
          'weekend show.';
      await tester.pumpApp(card(caption: caption));

      expect(find.textContaining('more', findRichText: true), findsOneWidget);

      await tester.ensureVisible(
        find.textContaining('more', findRichText: true),
      );
      await tester.tap(find.textContaining('more', findRichText: true));
      await tester.pump();

      expect(find.textContaining('more', findRichText: true), findsNothing);
    });

    testWidgets('the header identity (avatar + username) fires '
        'onProfileTap', (tester) async {
      var profileTaps = 0;
      await tester.pumpApp(card(onProfileTap: () => profileTaps++));

      // The header identity is ONE labelled control covering avatar and
      // username (the live-QA defect: neither navigated).
      await tester.tap(
        find.bySemanticsLabel('View eniola.stitches profile').first,
      );
      await tester.pump();

      expect(profileTaps, 1);
    });

    testWidgets('the caption leading username fires onProfileTap', (
      tester,
    ) async {
      var profileTaps = 0;
      await tester.pumpApp(card(onProfileTap: () => profileTaps++));

      // Tap inside the caption's first characters — the username span
      // (web PostDetailView parity).
      final caption = find.textContaining(
        'Ankara two-piece.',
        findRichText: true,
      );
      await tester.ensureVisible(caption);
      await tester.tapAt(tester.getTopLeft(caption) + const Offset(6, 8));
      await tester.pump();

      expect(profileTaps, 1);
    });

    testWidgets('without onProfileTap the header announces no dead '
        'button', (tester) async {
      await tester.pumpApp(card());

      expect(
        find.bySemanticsLabel('View eniola.stitches profile'),
        findsNothing,
      );
    });

    testWidgets('the cta axis follows onRequest', (tester) async {
      await tester.pumpApp(card());
      expect(find.text('Request this outfit'), findsNothing);

      await tester.pumpApp(card(onRequest: () {}));
      expect(find.text('Request this outfit'), findsOneWidget);
    });

    testWidgets('carousel media shows the count pill', (tester) async {
      await tester.pumpApp(card(mediaCount: 3));

      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('skeleton state renders the Skeleton anatomy', (
      tester,
    ) async {
      await tester.pumpApp(
        const SingleChildScrollView(
          child: SizedBox(
            width: 390,
            child: PostCard(
              username: 'x',
              media: <ImageProvider<Object>>[],
              liked: false,
              saved: false,
              likeCount: 0,
              caption: '',
              skeleton: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.text('x'), findsNothing);
    });
  });
}
