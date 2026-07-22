import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/data/first_action_flag.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// The app router (mobile-implementation.md §5): typed routes, a
/// StatefulShellRoute tab shell, and one top-level auth redirect.
///
/// The redirect is LIVE (auth cutover): every route except `/signin`
/// gates behind sign-in, and a signed-in user never sees `/signin` —
/// replacing the legacy push-only Navigator 1.0 chains (CV-7).
/// `refreshListenable` is bound to the session provider, so sign-in and
/// sign-out re-evaluate the redirect without manual navigation.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final sessionRefresh = ValueNotifier<int>(0);
  ref
    ..onDispose(sessionRefresh.dispose)
    ..listen(authSessionProvider, (previous, next) {
      sessionRefresh.value++;
    })
    // Prime the C1b flag at boot (SharedPreferences read) so the
    // synchronous redirect below has a resolved value by the time a
    // sign-in lands — the redirect itself must not await.
    ..listen(firstActionFlagProvider, (previous, next) {});
  final signInLocation = const SignInRoute().location;
  final homeLocation = const HomeRoute().location;
  final firstActionLocation = const FirstActionRoute().location;
  return GoRouter(
    routes: $appRoutes,
    initialLocation: homeLocation,
    refreshListenable: sessionRefresh,
    redirect: (context, state) {
      // Loading (restore in flight) reads as signed out: the C1 screen
      // doubles as the boot surface until the silent restore resolves.
      final signedIn = ref.read(authSessionProvider).value != null;
      final signingIn = state.matchedLocation == signInLocation;
      if (!signedIn) return signingIn ? null : signInLocation;
      if (signingIn) {
        // First sign-in hands off to the C1b interstitial (pages.md
        // C1b); an unresolved flag reads as seen — never strand a
        // sign-in on an extra screen it may already have dismissed.
        final firstActionSeen = ref.read(firstActionFlagProvider).value ?? true;
        return firstActionSeen ? homeLocation : firstActionLocation;
      }
      return null;
    },
  );
}
