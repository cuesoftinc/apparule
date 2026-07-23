import 'dart:async';

import 'package:apparule/src/core/ui/caught_up_divider.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/tab_bar.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_screen.dart';
import 'package:apparule/src/features/profile/data/notification_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';
import '../../../../helpers/reduced_motion.dart';

/// C10 over the seeded fake: day grouping, unread tint/dot for the
/// visit, read-state persisting to the repository (clearing the MI-16
/// badge), swipe-to-clear, deep links. 390px width.
void main() {
  // Pinned midday instant for the seed AND the rendering pass — the
  // calendar-day grouping (Today/Yesterday) otherwise flakes when the
  // wall clock sits within `created_hours_ago` of local midnight (the
  // seeded 3h-ago row slides onto Yesterday).
  DateTime fixedNow() => DateTime(2026, 7, 22, 12);

  Future<void> boot(
    WidgetTester tester, {
    NotificationRepositoryFake? notificationRepository,
  }) async {
    // Order-kind rows deep-link into the C8 detail, whose MI-14 pulse
    // repeats — §5 reduced motion keeps pumpAndSettle terminating.
    disableTestAnimations(tester);
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      notificationRepository:
          notificationRepository ?? NotificationRepositoryFake(now: fixedNow),
      overrides: <Override>[clockProvider.overrideWith((ref) => fixedNow)],
    );
  }

  Future<void> openNotifications(WidgetTester tester) async {
    unawaited(routerOf(tester).push(const NotificationsRoute().location));
    await tester.pumpAndSettle();
  }

  testWidgets('groups the seeded activity by day with the caught-up '
      'divider', (tester) async {
    await boot(tester);
    await openNotifications(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(
      find.textContaining('quoted your request #APR-1033'),
      findsOneWidget,
    );
    expect(
      find.textContaining('started work on your order #APR-1042'),
      findsOneWidget,
    );
    expect(find.byType(CaughtUpDivider), findsOneWidget);
  });

  testWidgets('opening the sheet marks everything read in the repository '
      'and clears the MI-16 Orders badge', (tester) async {
    final repository = NotificationRepositoryFake(now: fixedNow);
    await boot(tester, notificationRepository: repository);

    // The unread quote badges the Orders tab from boot.
    expect(
      find.descendant(
        of: find.byType(AppTabBar),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await openNotifications(tester);
    // The loaded visit still shows its unread rows; the repository —
    // the state the NEXT visit renders — is read.
    expect(await repository.unreadOrderCount(), 0);

    routerOf(tester).go(const HomeRoute().location);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppTabBar),
        matching: find.text('1'),
      ),
      findsNothing,
    );
  });

  testWidgets('swipe-to-clear removes the row from the repository', (
    tester,
  ) async {
    final repository = NotificationRepositoryFake(now: fixedNow);
    await boot(tester, notificationRepository: repository);
    await openNotifications(tester);

    final row = find.textContaining('ada.eze liked your comment');
    expect(row, findsOneWidget);
    await tester.drag(row, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(row, findsNothing);
    final remaining = await repository.notifications();
    expect(remaining.map((n) => n.id), isNot(contains('ntf-4')));
  });

  testWidgets('an order-kind row deep-links into C8 detail', (
    tester,
  ) async {
    await boot(tester);
    await openNotifications(tester);

    await tester.tap(
      find.textContaining('quoted your request #APR-1033'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.text('Pay ₦40,000'), findsOneWidget);
  });

  testWidgets('a follow row carries the MI-7 Follow trailing whose morph '
      'mutates the graph', (tester) async {
    // Follow rows live in the designer-side stream (the seed's follow
    // notification belongs to des-tunde's audience).
    await boot(
      tester,
      notificationRepository: NotificationRepositoryFake(
        now: fixedNow,
        audienceIds: const <String>{'des-tunde'},
      ),
    );
    await openNotifications(tester);

    // The follow row's actor (funmi.b) isn't followed yet → gradient
    // "Follow" (NotificationRow contract trailing).
    expect(find.textContaining('started following you'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);

    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();

    expect(find.text('Follow'), findsNothing);
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets("a follow row links to the follower's C9 profile", (
    tester,
  ) async {
    await boot(
      tester,
      notificationRepository: NotificationRepositoryFake(
        now: fixedNow,
        audienceIds: const <String>{'des-tunde'},
      ),
    );
    await openNotifications(tester);

    await tester.tap(find.textContaining('started following you'));
    await tester.pumpAndSettle();

    expect(find.byType(PublicProfileScreen), findsOneWidget);
  });

  testWidgets('an empty sheet renders the notifications empty state', (
    tester,
  ) async {
    await boot(
      tester,
      notificationRepository: NotificationRepositoryFake(
        now: fixedNow,
        bundle: _EmptyAssetBundle(),
      ),
    );
    await openNotifications(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Back to feed'), findsOneWidget);
  });
  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await boot(tester);
    await openNotifications(tester);
    await expectContentClearOfTopInsets(tester);
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
