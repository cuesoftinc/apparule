import 'package:apparule/src/core/ui/app_shell.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_screen.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_screen.dart';
import 'package:apparule/src/features/feed/presentation/create_screen.dart';
import 'package:apparule/src/features/feed/presentation/explore_screen.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:apparule/src/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'routes.g.dart';

// Typed route classes (go_router_builder, mobile-implementation.md §5).
// This wave carries the five tab branches plus the routed feature
// placeholders; the remaining §5 route map (post/{id}, request/{postId},
// capture, notifications, …) lands with its screens.

/// The persistent tab shell — Home · Explore · ➕ · Orders · Profile
/// (pages.md Part C).
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
    TypedStatefulShellBranch<CreateBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CreateRoute>(path: '/create'),
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

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AppShell(navigationShell: navigationShell);
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

class CreateBranch extends StatefulShellBranchData {
  const CreateBranch();
}

class CreateRoute extends GoRouteData with $CreateRoute {
  const CreateRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CreateScreen();
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
