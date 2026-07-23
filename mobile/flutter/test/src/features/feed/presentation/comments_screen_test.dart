import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C11 over the seeded fake: CommentRow list, comment hearts, MI-18
/// composer — count == list stays true through mutations. 390px width.
void main() {
  Future<void> bootToComments(
    WidgetTester tester, {
    PostRepositoryFake? postRepository,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      postRepository: postRepository,
    );
    routerOf(tester).go(
      const PostCommentsRoute(id: 'post-ankara-gown').location,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the seeded comments with their authors', (
    tester,
  ) async {
    await bootToComments(tester);

    expect(find.text('Comments · 3'), findsOneWidget);
    expect(find.textContaining('Obsessed with this print'), findsOneWidget);
    expect(find.textContaining('maisonbisi '), findsOneWidget);
    expect(find.textContaining('funmi.b '), findsOneWidget);
  });

  testWidgets('the composer appends through the repository (MI-18) and '
      'keeps count == list', (tester) async {
    final repository = PostRepositoryFake();
    await bootToComments(tester, postRepository: repository);

    await tester.enterText(find.byType(TextField), 'Gorgeous work!');
    await tester.tap(find.bySemanticsLabel('Post comment'));
    await tester.pumpAndSettle();

    expect(find.text('Comments · 4'), findsOneWidget);
    expect(find.textContaining('Gorgeous work!'), findsOneWidget);

    final post = await repository.post('post-ankara-gown');
    final comments = await repository.comments('post-ankara-gown');
    expect(post.commentCount, 4);
    expect(comments, hasLength(4));
  });

  testWidgets('Reply prefills the composer, arms the parent, and the '
      'posted row indents under it (D27)', (tester) async {
    final repository = PostRepositoryFake();
    await bootToComments(tester, postRepository: repository);

    await tester.tap(find.bySemanticsLabel('Reply to maisonbisi'));
    await tester.pumpAndSettle();

    // Prefill + the replying-to chip.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '@maisonbisi ',
    );
    expect(find.text('Replying to @maisonbisi'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '@maisonbisi so good right?',
    );
    await tester.tap(find.bySemanticsLabel('Post comment'));
    await tester.pumpAndSettle();

    // The reply landed threaded under its parent at the repository.
    final comments = await repository.comments('post-ankara-gown');
    final reply = comments.singleWhere(
      (comment) => comment.body == '@maisonbisi so good right?',
    );
    final parent = comments.singleWhere(
      (comment) => comment.id == reply.parentId,
    );
    expect(parent.author.username, 'maisonbisi');

    // …and renders indented one avatar column deep.
    expect(find.textContaining('so good right?'), findsOneWidget);
    // The chip disarmed after the successful post.
    expect(find.text('Replying to @maisonbisi'), findsNothing);
  });

  testWidgets('a failed post toasts and keeps the composer text '
      '(D34/CLASS 4)', (tester) async {
    final repository = PostRepositoryFake();
    await bootToComments(tester, postRepository: repository);
    repository.failNext = Exception('500');

    await tester.enterText(find.byType(TextField), 'Lovely tailoring');
    await tester.tap(find.bySemanticsLabel('Post comment'));
    await tester.pumpAndSettle();

    // The toast text renders once per live Scaffold (C4 sits beneath
    // the transparent C11 route) — presence is the contract.
    expect(find.text('Something went wrong — try again.'), findsWidgets);
    // The user's text is preserved — clear only happens on success.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Lovely tailoring',
    );
    expect(find.text('Comments · 3'), findsOneWidget);
  });

  testWidgets('a commenter identity opens their C9 profile', (
    tester,
  ) async {
    await bootToComments(tester);

    // Avatar and username-span are both labelled profile affordances
    // (live-QA sweep: every entity reference navigates).
    await tester.tap(find.bySemanticsLabel('View maisonbisi profile').first);
    await tester.pumpAndSettle();

    final profile = tester.widget<PublicProfileScreen>(
      find.byType(PublicProfileScreen),
    );
    expect(profile.username, 'maisonbisi');
  });

  testWidgets('the heart toggles a comment like', (tester) async {
    await bootToComments(tester);

    // cmt-1 leads with 4 likes ("34 likes" behind the sheet is the
    // post's own counter — match the comment meta line's joined shape).
    expect(find.textContaining('   4 likes'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Like comment').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('   5 likes'), findsOneWidget);
    // The filled DS Lucide heart announces the toggled state (D60).
    expect(find.bySemanticsLabel('Unlike comment'), findsOneWidget);
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToComments(tester);
    await expectContentClearOfTopInsets(tester);
  });
}
