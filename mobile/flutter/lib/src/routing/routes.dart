import 'dart:async';

import 'package:apparule/src/core/ui/app_shell.dart';
import 'package:apparule/src/features/auth/presentation/first_action_screen.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_screen.dart';
import 'package:apparule/src/features/earnings/presentation/designer_onboarding_screen.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_screen.dart';
import 'package:apparule/src/features/earnings/presentation/payout_account_screen.dart';
import 'package:apparule/src/features/feed/presentation/comments_screen.dart';
import 'package:apparule/src/features/feed/presentation/explore_screen.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:apparule/src/features/feed/presentation/post_detail_screen.dart';
import 'package:apparule/src/features/measurements/presentation/capture_screen.dart';
import 'package:apparule/src/features/measurements/presentation/create_chooser.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_screen.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_screen.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:apparule/src/features/orders/presentation/request_stepper_screen.dart';
import 'package:apparule/src/features/profile/presentation/account_data_screen.dart';
import 'package:apparule/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_screen.dart';
import 'package:apparule/src/features/profile/presentation/follow_list_view_model.dart';
import 'package:apparule/src/features/profile/presentation/notification_settings_screen.dart';
import 'package:apparule/src/features/profile/presentation/notifications_screen.dart';
import 'package:apparule/src/features/profile/presentation/notifications_view_model.dart';
import 'package:apparule/src/features/profile/presentation/orders_badge_sync.dart';
import 'package:apparule/src/features/profile/presentation/privacy_settings_screen.dart';
import 'package:apparule/src/features/profile/presentation/profile_screen.dart';
import 'package:apparule/src/features/profile/presentation/public_profile_screen.dart';
import 'package:apparule/src/features/profile/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'routes.g.dart';

// Typed route classes (go_router_builder, mobile-implementation.md §5).
// The tab shell carries the five branches; the feed/orders wave adds the
// §5 social+commerce routes (post/{id} + comments, request/{postId},
// orders/{id}, notifications) as full-screen top-level routes — their
// canvases render without the tab bar (C4/C5/C8-detail/C10/C11).

/// The persistent tab shell — Home · Explore · ➕ · Orders · Profile
/// (pages.md Part C). Four branches behind the five slots: ➕ is an
/// entry gesture, not a branch (canvas-first ruling 2026-07-22 — the
/// `/create` placeholder had no pages.md spec and no canvas frame; the
/// designer composer arrives designed-first with its own frames).
@TypedStatefulShellRoute<AppShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<HomeBranch>(
      routes: <TypedRoute<RouteData>>[TypedGoRoute<HomeRoute>(path: '/')],
    ),
    TypedStatefulShellBranch<ExploreBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ExploreRoute>(path: '/explore'),
      ],
    ),
    TypedStatefulShellBranch<OrdersBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<OrdersRoute>(path: '/orders'),
      ],
    ),
    TypedStatefulShellBranch<ProfileBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ProfileRoute>(path: '/profile'),
      ],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  /// The Orders branch's position in the shell's branch list.
  static const int _ordersBranchIndex = 2;

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        // MI-16: unread order-kind notifications badge the Orders tab;
        // opening C10 marks them read and clears it.
        final ordersBadge = ref.watch(ordersTabBadgeProvider).value;
        // MI-16 (D22): the badge ALSO clears on Orders tab visit — the
        // web DashboardShell effect, mirrored: whenever the Orders
        // branch is active with a non-zero badge, mark order kinds read
        // post-frame (mutating providers inside build is off-limits).
        if (navigationShell.currentIndex == _ordersBranchIndex &&
            (ordersBadge ?? 0) > 0) {
          final sync = ref.read(ordersBadgeSyncProvider.notifier);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(sync.markVisited());
          });
        }
        return AppShell(
          navigationShell: navigationShell,
          ordersBadge: ordersBadge,
          // ➕ = the unified create chooser (M-11, canvas 548:2725):
          // "Take measurements" (guide on first run, §10) · "Post an
          // outfit" (designer-gated → C13 until the C15 composer ships).
          onCreate: () => unawaited(showCreateChooser(context)),
        );
      },
    );
  }
}

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const HomeFeedScreen();
}

class ExploreBranch extends StatefulShellBranchData {
  const ExploreBranch();
}

class ExploreRoute extends GoRouteData with $ExploreRoute {
  const ExploreRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ExploreScreen();
}

class OrdersBranch extends StatefulShellBranchData {
  const OrdersBranch();
}

class OrdersRoute extends GoRouteData with $OrdersRoute {
  const OrdersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const OrdersScreen();
}

class ProfileBranch extends StatefulShellBranchData {
  const ProfileBranch();
}

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileScreen();
}

/// C1 — outside the shell: the auth redirect (stubbed this wave) sends
/// signed-out users here once the auth wave lands.
@TypedGoRoute<SignInRoute>(path: '/signin')
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SignInScreen();
}

/// C1b — the post-signup interstitial (pages.md C1b; §5 route map):
/// a FIRST sign-in redirects here instead of home; every exit marks the
/// persisted flag so later sign-ins skip it.
@TypedGoRoute<FirstActionRoute>(path: '/onboarding/first-action')
class FirstActionRoute extends GoRouteData with $FirstActionRoute {
  const FirstActionRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const FirstActionScreen();
}

/// C6 — deep-linkable capture flow, full-screen outside the tab shell
/// (mobile-implementation.md §10). The guide and the MI-13 manual
/// fallback are SIBLING routes under the `/capture` prefix, not nested
/// children — nesting would stack a live CaptureScreen (camera and all)
/// beneath them on every deep link.
@TypedGoRoute<CaptureRoute>(path: '/capture')
class CaptureRoute extends GoRouteData with $CaptureRoute {
  const CaptureRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CaptureScreen();
}

/// C6's instructional guide — the first-run ➕ entry (§10).
@TypedGoRoute<CaptureGuideRoute>(path: '/capture/guide')
class CaptureGuideRoute extends GoRouteData with $CaptureGuideRoute {
  const CaptureGuideRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CaptureGuideScreen();
}

/// MI-13 manual entry — the fallback for QC that never clears or a
/// denied camera (flows/vault.md §1/§2).
@TypedGoRoute<ManualEntryRoute>(path: '/capture/manual')
class ManualEntryRoute extends GoRouteData with $ManualEntryRoute {
  const ManualEntryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ManualEntryScreen();
}

/// C7 — reached from the Profile tab header ring (pages.md Part C).
@TypedGoRoute<VaultRoute>(path: '/vault')
class VaultRoute extends GoRouteData with $VaultRoute {
  const VaultRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const VaultScreen();
}

/// C14 — payout push notifications deep-link here (pages.md Part C).
@TypedGoRoute<EarningsRoute>(path: '/earnings')
class EarningsRoute extends GoRouteData with $EarningsRoute {
  const EarningsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const EarningsScreen();
}

/// C4 — post detail, full-screen over the shell; the app-link target for
/// `apparule.cuesoft.io/p/{post_id}` permalinks (§5). C11's comments
/// route nests beneath so a comments deep link stacks the post under it.
@TypedGoRoute<PostDetailRoute>(
  path: '/post/:id',
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<PostCommentsRoute>(path: 'comments'),
  ],
)
class PostDetailRoute extends GoRouteData with $PostDetailRoute {
  const PostDetailRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PostDetailScreen(postId: id);
}

/// C11 — the full-height comments sheet over the dimmed post (pages.md
/// [Directive 2026-07-18]): a transparent page, so C4 stays visible
/// beneath the scrim.
class PostCommentsRoute extends GoRouteData with $PostCommentsRoute {
  const PostCommentsRoute({required this.id});

  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierColor: const Color(0x80000000),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
            position: animation.drive(
              Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
            ),
            child: child,
          ),
      child: CommentsScreen(postId: id),
    );
  }
}

/// C5 — the request stepper (MI-10), reached from a post's Request CTA,
/// never a blank compose surface (§5 ➕ note).
@TypedGoRoute<RequestRoute>(path: '/request/:postId')
class RequestRoute extends GoRouteData with $RequestRoute {
  const RequestRoute({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      RequestStepperScreen(postId: postId);
}

/// C8 detail — push notifications deep-link here (pages.md C8).
@TypedGoRoute<OrderDetailRoute>(path: '/orders/:id')
class OrderDetailRoute extends GoRouteData with $OrderDetailRoute {
  const OrderDetailRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OrderDetailScreen(orderId: id);
}

/// C10 — the activity sheet (profile feature, §3: its entry points are
/// the C2 top-bar bell and the profile tab's bell affordance).
@TypedGoRoute<NotificationsRoute>(path: '/notifications')
class NotificationsRoute extends GoRouteData with $NotificationsRoute {
  const NotificationsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationsScreen();
}

/// C9 — edit profile. Declared BEFORE the `/profile/:username` param
/// route: go_router walks routes in declaration order, so the literal
/// segment must win over `username: "edit"`.
@TypedGoRoute<EditProfileRoute>(path: '/profile/edit')
class EditProfileRoute extends GoRouteData with $EditProfileRoute {
  const EditProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const EditProfileScreen();
}

/// C9 — another user's profile (pages.md: others = B6). C12's
/// followers/following lists nest beneath, so a list deep link stacks
/// the profile under it.
@TypedGoRoute<PublicProfileRoute>(
  path: '/profile/:username',
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<FollowersRoute>(path: 'followers'),
    TypedGoRoute<FollowingRoute>(path: 'following'),
  ],
)
class PublicProfileRoute extends GoRouteData with $PublicProfileRoute {
  const PublicProfileRoute({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PublicProfileScreen(username: username);
}

/// C12 — followers tab ([Directive 2026-07-18]: = B6 lists).
class FollowersRoute extends GoRouteData with $FollowersRoute {
  const FollowersRoute({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, GoRouterState state) => FollowListScreen(
    username: username,
    initialKind: FollowListKind.followers,
  );
}

/// C12 — following tab.
class FollowingRoute extends GoRouteData with $FollowingRoute {
  const FollowingRoute({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, GoRouterState state) => FollowListScreen(
    username: username,
    initialKind: FollowListKind.following,
  );
}

/// B7 — settings (C9's gear). The three sub-screens nest beneath so a
/// sub-screen deep link stacks the root under it.
@TypedGoRoute<SettingsRoute>(
  path: '/settings',
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<NotificationSettingsRoute>(path: 'notifications'),
    TypedGoRoute<PrivacySettingsRoute>(path: 'privacy'),
    TypedGoRoute<AccountDataRoute>(path: 'account'),
  ],
)
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}

/// B7 sub-screen — per-event notification toggles.
class NotificationSettingsRoute extends GoRouteData
    with $NotificationSettingsRoute {
  const NotificationSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationSettingsScreen();
}

/// B7 sub-screen — privacy & consent.
class PrivacySettingsRoute extends GoRouteData with $PrivacySettingsRoute {
  const PrivacySettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrivacySettingsScreen();
}

/// B7 sub-screen — account & data (the danger ladder lives here).
class AccountDataRoute extends GoRouteData with $AccountDataRoute {
  const AccountDataRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AccountDataScreen();
}

/// C13 — designer onboarding intro (§5 route map).
@TypedGoRoute<DesignerOnboardingRoute>(path: '/designer/onboarding')
class DesignerOnboardingRoute extends GoRouteData
    with $DesignerOnboardingRoute {
  const DesignerOnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DesignerOnboardingScreen();
}

/// C13 — the payout banking form. A SIBLING under the prefix, not a
/// child (the capture-guide precedent): nesting would stack a stale
/// intro beneath every re-verification entry (C8 banner, C14 chip).
@TypedGoRoute<PayoutAccountRoute>(path: '/designer/onboarding/payout')
class PayoutAccountRoute extends GoRouteData with $PayoutAccountRoute {
  const PayoutAccountRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PayoutAccountScreen();
}
