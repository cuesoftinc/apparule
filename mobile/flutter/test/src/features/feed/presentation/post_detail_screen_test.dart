import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/comments_screen.dart';
import 'package:apparule/src/features/orders/presentation/request_stepper_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C4 over the seeded fake: full anatomy, like mutation shared with the
/// repository, comments entry, pinned Request CTA → C5. 390px width.
void main() {
  Future<void> bootToPost(
    WidgetTester tester, {
    PostRepositoryFake? postRepository,
    String postId = 'post-agbada',
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
    routerOf(tester).go(PostDetailRoute(id: postId).location);
    await tester.pumpAndSettle();
  }

  testWidgets('renders the post anatomy from seed', (tester) async {
    await bootToPost(tester);

    expect(find.text('Post'), findsOneWidget);
    expect(find.text('tunde.o'), findsOneWidget);
    expect(find.text('27 likes'), findsOneWidget);
    expect(find.text('View all 4 comments'), findsOneWidget);
    expect(find.text('Request this outfit'), findsOneWidget);
  });

  testWidgets('liking on C4 mutates the same repository truth C2 reads', (
    tester,
  ) async {
    final repository = PostRepositoryFake();
    await bootToPost(tester, postRepository: repository);

    await tester.tap(find.bySemanticsLabel('Like'));
    await tester.pumpAndSettle();
    expect(find.text('28 likes'), findsOneWidget);

    final post = await repository.post('post-agbada');
    expect(post.liked, isTrue);
    expect(post.likeCount, 28);
  });

  testWidgets('the comments entry opens the C11 sheet', (tester) async {
    await bootToPost(tester);

    await tester.tap(find.text('View all 4 comments'));
    await tester.pumpAndSettle();

    expect(find.byType(CommentsScreen), findsOneWidget);
  });

  testWidgets('the pinned CTA hands off to the C5 stepper', (tester) async {
    await bootToPost(tester);

    await tester.tap(find.text('Request this outfit'));
    await tester.pumpAndSettle();

    expect(find.byType(RequestStepperScreen), findsOneWidget);
    expect(find.text('New request · 1 of 3'), findsOneWidget);
  });

  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToPost(tester);
    expectNoContentInTopInset(tester);
  });
}
