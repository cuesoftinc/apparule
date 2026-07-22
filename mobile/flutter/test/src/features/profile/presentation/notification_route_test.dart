import 'package:apparule/src/features/profile/domain/app_notification.dart';
import 'package:apparule/src/features/profile/presentation/notification_route.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The CLASS 7 lock: notificationRoute is EXHAUSTIVE over
/// NotificationKind — every kind is pinned to its destination route
/// TYPE and payload here, so `payout` can never silently ride a
/// grouping getter into OrderDetail again (D21). A new kind fails the
/// switch at compile time and this table at review time.
void main() {
  AppNotification notification(NotificationKind kind) => AppNotification(
    id: 'ntf-test',
    kind: kind,
    payloadRef: kind.isOrderKind ? 'ord-1033' : 'post-asooke-set',
    text: 'test',
    actorUsername: 'amara.designs',
    createdAt: DateTime.utc(2026, 7, 22, 12),
  );

  test('every kind maps to its ratified destination — exhaustively', () {
    // One entry per kind; the exhaustive switch inside notificationRoute
    // guarantees no kind is missing from THIS table either.
    final expectations = <NotificationKind, void Function(GoRouteData)>{
      NotificationKind.quote: (route) {
        route as OrderDetailRoute;
        expect(route.id, 'ord-1033');
      },
      NotificationKind.statusChange: (route) {
        route as OrderDetailRoute;
        expect(route.id, 'ord-1033');
      },
      // D21: payout lands on C14 earnings, NEVER OrderDetail.
      NotificationKind.payout: (route) {
        expect(route, isA<EarningsRoute>());
        expect(route, isNot(isA<OrderDetailRoute>()));
      },
      NotificationKind.follow: (route) {
        route as PublicProfileRoute;
        expect(route.username, 'amara.designs');
      },
      NotificationKind.comment: (route) {
        route as PostDetailRoute;
        expect(route.id, 'post-asooke-set');
      },
      NotificationKind.like: (route) {
        route as PostDetailRoute;
        expect(route.id, 'post-asooke-set');
      },
    };

    expect(
      expectations.keys,
      containsAll(NotificationKind.values),
      reason: 'the expectation table must stay exhaustive',
    );
    for (final entry in expectations.entries) {
      entry.value(notificationRoute(notification(entry.key)));
    }
  });
}
