import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/feed/presentation/comments_screen.dart';
import 'package:apparule/src/features/feed/presentation/post_detail_screen.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_screen.dart';
import 'package:apparule/src/features/orders/presentation/request_stepper_screen.dart';
import 'package:apparule/src/features/profile/presentation/notifications_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/boot_app.dart';

/// The feed/orders wave's §5 routes: typed locations and deep-link
/// resolution (post permalinks arrive as `/post/{id}` app links; order
/// push notifications deep-link `/orders/{id}`).
void main() {
  AuthRepositoryFake signedIn() =>
      AuthRepositoryFake(initialSession: AuthRepositoryFake.seedSession);

  test('typed routes carry the §5 paths', () {
    expect(const PostDetailRoute(id: 'post-x').location, '/post/post-x');
    expect(
      const PostCommentsRoute(id: 'post-x').location,
      '/post/post-x/comments',
    );
    expect(const RequestRoute(postId: 'post-x').location, '/request/post-x');
    expect(const OrderDetailRoute(id: 'req-1').location, '/orders/req-1');
    expect(const NotificationsRoute().location, '/notifications');
  });

  testWidgets('deep links resolve their screens over the seeded fakes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(tester, authRepository: signedIn());
    final router = routerOf(tester)
      ..go(const PostDetailRoute(id: 'post-agbada').location);
    await tester.pumpAndSettle();
    expect(find.byType(PostDetailScreen), findsOneWidget);

    // A comments deep link stacks C4 beneath the sheet.
    router.go(const PostCommentsRoute(id: 'post-agbada').location);
    await tester.pumpAndSettle();
    expect(find.byType(CommentsScreen), findsOneWidget);
    expect(find.byType(PostDetailScreen), findsOneWidget);

    router.go(const RequestRoute(postId: 'post-agbada').location);
    await tester.pumpAndSettle();
    expect(find.byType(RequestStepperScreen), findsOneWidget);

    router.go(const OrderDetailRoute(id: 'req-apr-1042').location);
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailScreen), findsOneWidget);

    router.go(const NotificationsRoute().location);
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
  });

  testWidgets('the new routes gate behind sign-in like every other', (
    tester,
  ) async {
    await pumpBootedApp(tester);

    routerOf(tester).go(const NotificationsRoute().location);
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
