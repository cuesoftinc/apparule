import 'package:apparule/src/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// The app router (mobile-implementation.md §5): typed routes, a
/// StatefulShellRoute tab shell, and one top-level auth redirect.
///
/// The redirect is STUBBED to always-allow this wave — the auth wave binds
/// it to the session provider (via `refreshListenable`) so every route
/// except `/signin` gates behind sign-in, replacing the legacy push-only
/// Navigator 1.0 chains (CV-7).
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    routes: $appRoutes,
    initialLocation: const HomeRoute().location,
    redirect: (context, state) => null,
  );
}
