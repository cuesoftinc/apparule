import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
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

  testWidgets('the heart toggles a comment like', (tester) async {
    await bootToComments(tester);

    // cmt-1 leads with 4 likes ("34 likes" behind the sheet is the
    // post's own counter — match the comment meta line shape).
    expect(find.textContaining('4 likes   Reply'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('5 likes   Reply'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToComments(tester);
    await expectContentClearOfTopInsets(tester);
  });
}
