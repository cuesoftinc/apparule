import 'package:apparule/src/features/profile/domain/app_notification.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:go_router/go_router.dart';

/// THE `NotificationKind → destination` mapping (the interaction audit's
/// CLASS 7 lock): one EXHAUSTIVE switch — no kind can silently ride a
/// grouping getter the way `payout` rode `isOrderKind` into OrderDetail
/// (D21). The exhaustive unit test pins every kind to a route type;
/// adding a kind fails compilation here first.
GoRouteData notificationRoute(AppNotification notification) =>
    switch (notification.kind) {
      // Order kinds deep-link into the C8 detail the payload names.
      NotificationKind.quote ||
      NotificationKind.statusChange => OrderDetailRoute(
        id: notification.payloadRef,
      ),
      // Payouts land on C14 earnings — never OrderDetail (D21).
      NotificationKind.payout => const EarningsRoute(),
      // Social kinds: the follower's C9 profile / the post's C4 detail.
      NotificationKind.follow => PublicProfileRoute(
        username: notification.actorUsername,
      ),
      NotificationKind.comment ||
      NotificationKind.like => PostDetailRoute(id: notification.payloadRef),
    };
