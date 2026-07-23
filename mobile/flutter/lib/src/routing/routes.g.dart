// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $appShellRoute,
  $signInRoute,
  $firstActionRoute,
  $captureRoute,
  $captureGuideRoute,
  $manualEntryRoute,
  $vaultRoute,
  $earningsRoute,
  $postDetailRoute,
  $composerRoute,
  $requestRoute,
  $orderDetailRoute,
  $notificationsRoute,
  $editProfileRoute,
  $publicProfileRoute,
  $settingsRoute,
  $designerOnboardingRoute,
  $payoutAccountRoute,
];

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/',
          hasOverriddenOnExit: false,
          factory: $HomeRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/explore',
          hasOverriddenOnExit: false,
          factory: $ExploreRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/orders',
          hasOverriddenOnExit: false,
          factory: $OrdersRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/profile',
          hasOverriddenOnExit: false,
          factory: $ProfileRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ExploreRoute on GoRouteData {
  static ExploreRoute _fromState(GoRouterState state) => const ExploreRoute();

  @override
  String get location => GoRouteData.$location('/explore');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $OrdersRoute on GoRouteData {
  static OrdersRoute _fromState(GoRouterState state) => const OrdersRoute();

  @override
  String get location => GoRouteData.$location('/orders');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProfileRoute on GoRouteData {
  static ProfileRoute _fromState(GoRouterState state) => const ProfileRoute();

  @override
  String get location => GoRouteData.$location('/profile');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $signInRoute => GoRouteData.$route(
  path: '/signin',
  hasOverriddenOnExit: false,
  factory: $SignInRoute._fromState,
);

mixin $SignInRoute on GoRouteData {
  static SignInRoute _fromState(GoRouterState state) => const SignInRoute();

  @override
  String get location => GoRouteData.$location('/signin');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $firstActionRoute => GoRouteData.$route(
  path: '/onboarding/first-action',
  hasOverriddenOnExit: false,
  factory: $FirstActionRoute._fromState,
);

mixin $FirstActionRoute on GoRouteData {
  static FirstActionRoute _fromState(GoRouterState state) =>
      const FirstActionRoute();

  @override
  String get location => GoRouteData.$location('/onboarding/first-action');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $captureRoute => GoRouteData.$route(
  path: '/capture',
  hasOverriddenOnExit: false,
  factory: $CaptureRoute._fromState,
);

mixin $CaptureRoute on GoRouteData {
  static CaptureRoute _fromState(GoRouterState state) => const CaptureRoute();

  @override
  String get location => GoRouteData.$location('/capture');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $captureGuideRoute => GoRouteData.$route(
  path: '/capture/guide',
  hasOverriddenOnExit: false,
  factory: $CaptureGuideRoute._fromState,
);

mixin $CaptureGuideRoute on GoRouteData {
  static CaptureGuideRoute _fromState(GoRouterState state) =>
      const CaptureGuideRoute();

  @override
  String get location => GoRouteData.$location('/capture/guide');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $manualEntryRoute => GoRouteData.$route(
  path: '/capture/manual',
  hasOverriddenOnExit: false,
  factory: $ManualEntryRoute._fromState,
);

mixin $ManualEntryRoute on GoRouteData {
  static ManualEntryRoute _fromState(GoRouterState state) =>
      const ManualEntryRoute();

  @override
  String get location => GoRouteData.$location('/capture/manual');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $vaultRoute => GoRouteData.$route(
  path: '/vault',
  hasOverriddenOnExit: false,
  factory: $VaultRoute._fromState,
);

mixin $VaultRoute on GoRouteData {
  static VaultRoute _fromState(GoRouterState state) => const VaultRoute();

  @override
  String get location => GoRouteData.$location('/vault');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $earningsRoute => GoRouteData.$route(
  path: '/earnings',
  hasOverriddenOnExit: false,
  factory: $EarningsRoute._fromState,
);

mixin $EarningsRoute on GoRouteData {
  static EarningsRoute _fromState(GoRouterState state) => const EarningsRoute();

  @override
  String get location => GoRouteData.$location('/earnings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $postDetailRoute => GoRouteData.$route(
  path: '/post/:id',
  hasOverriddenOnExit: false,
  factory: $PostDetailRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'comments',
      hasOverriddenOnExit: false,
      factory: $PostCommentsRoute._fromState,
    ),
  ],
);

mixin $PostDetailRoute on GoRouteData {
  static PostDetailRoute _fromState(GoRouterState state) =>
      PostDetailRoute(id: state.pathParameters['id']!);

  PostDetailRoute get _self => this as PostDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/post/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PostCommentsRoute on GoRouteData {
  static PostCommentsRoute _fromState(GoRouterState state) =>
      PostCommentsRoute(id: state.pathParameters['id']!);

  PostCommentsRoute get _self => this as PostCommentsRoute;

  @override
  String get location =>
      GoRouteData.$location('/post/${Uri.encodeComponent(_self.id)}/comments');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $composerRoute => GoRouteData.$route(
  path: '/create/post',
  hasOverriddenOnExit: false,
  factory: $ComposerRoute._fromState,
);

mixin $ComposerRoute on GoRouteData {
  static ComposerRoute _fromState(GoRouterState state) => const ComposerRoute();

  @override
  String get location => GoRouteData.$location('/create/post');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $requestRoute => GoRouteData.$route(
  path: '/request/:postId',
  hasOverriddenOnExit: false,
  factory: $RequestRoute._fromState,
);

mixin $RequestRoute on GoRouteData {
  static RequestRoute _fromState(GoRouterState state) =>
      RequestRoute(postId: state.pathParameters['postId']!);

  RequestRoute get _self => this as RequestRoute;

  @override
  String get location =>
      GoRouteData.$location('/request/${Uri.encodeComponent(_self.postId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $orderDetailRoute => GoRouteData.$route(
  path: '/orders/:id',
  hasOverriddenOnExit: false,
  factory: $OrderDetailRoute._fromState,
);

mixin $OrderDetailRoute on GoRouteData {
  static OrderDetailRoute _fromState(GoRouterState state) =>
      OrderDetailRoute(id: state.pathParameters['id']!);

  OrderDetailRoute get _self => this as OrderDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/orders/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $notificationsRoute => GoRouteData.$route(
  path: '/notifications',
  hasOverriddenOnExit: false,
  factory: $NotificationsRoute._fromState,
);

mixin $NotificationsRoute on GoRouteData {
  static NotificationsRoute _fromState(GoRouterState state) =>
      const NotificationsRoute();

  @override
  String get location => GoRouteData.$location('/notifications');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $editProfileRoute => GoRouteData.$route(
  path: '/profile/edit',
  hasOverriddenOnExit: false,
  factory: $EditProfileRoute._fromState,
);

mixin $EditProfileRoute on GoRouteData {
  static EditProfileRoute _fromState(GoRouterState state) =>
      const EditProfileRoute();

  @override
  String get location => GoRouteData.$location('/profile/edit');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $publicProfileRoute => GoRouteData.$route(
  path: '/profile/:username',
  hasOverriddenOnExit: false,
  factory: $PublicProfileRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'followers',
      hasOverriddenOnExit: false,
      factory: $FollowersRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'following',
      hasOverriddenOnExit: false,
      factory: $FollowingRoute._fromState,
    ),
  ],
);

mixin $PublicProfileRoute on GoRouteData {
  static PublicProfileRoute _fromState(GoRouterState state) =>
      PublicProfileRoute(username: state.pathParameters['username']!);

  PublicProfileRoute get _self => this as PublicProfileRoute;

  @override
  String get location =>
      GoRouteData.$location('/profile/${Uri.encodeComponent(_self.username)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FollowersRoute on GoRouteData {
  static FollowersRoute _fromState(GoRouterState state) =>
      FollowersRoute(username: state.pathParameters['username']!);

  FollowersRoute get _self => this as FollowersRoute;

  @override
  String get location => GoRouteData.$location(
    '/profile/${Uri.encodeComponent(_self.username)}/followers',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FollowingRoute on GoRouteData {
  static FollowingRoute _fromState(GoRouterState state) =>
      FollowingRoute(username: state.pathParameters['username']!);

  FollowingRoute get _self => this as FollowingRoute;

  @override
  String get location => GoRouteData.$location(
    '/profile/${Uri.encodeComponent(_self.username)}/following',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingsRoute => GoRouteData.$route(
  path: '/settings',
  hasOverriddenOnExit: false,
  factory: $SettingsRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'notifications',
      hasOverriddenOnExit: false,
      factory: $NotificationSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'privacy',
      hasOverriddenOnExit: false,
      factory: $PrivacySettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'account',
      hasOverriddenOnExit: false,
      factory: $AccountDataRoute._fromState,
    ),
  ],
);

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NotificationSettingsRoute on GoRouteData {
  static NotificationSettingsRoute _fromState(GoRouterState state) =>
      const NotificationSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/notifications');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PrivacySettingsRoute on GoRouteData {
  static PrivacySettingsRoute _fromState(GoRouterState state) =>
      const PrivacySettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/privacy');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountDataRoute on GoRouteData {
  static AccountDataRoute _fromState(GoRouterState state) =>
      const AccountDataRoute();

  @override
  String get location => GoRouteData.$location('/settings/account');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $designerOnboardingRoute => GoRouteData.$route(
  path: '/designer/onboarding',
  hasOverriddenOnExit: false,
  factory: $DesignerOnboardingRoute._fromState,
);

mixin $DesignerOnboardingRoute on GoRouteData {
  static DesignerOnboardingRoute _fromState(GoRouterState state) =>
      const DesignerOnboardingRoute();

  @override
  String get location => GoRouteData.$location('/designer/onboarding');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $payoutAccountRoute => GoRouteData.$route(
  path: '/designer/onboarding/payout',
  hasOverriddenOnExit: false,
  factory: $PayoutAccountRoute._fromState,
);

mixin $PayoutAccountRoute on GoRouteData {
  static PayoutAccountRoute _fromState(GoRouterState state) =>
      const PayoutAccountRoute();

  @override
  String get location => GoRouteData.$location('/designer/onboarding/payout');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
