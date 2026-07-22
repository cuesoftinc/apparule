import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'first_action_flag.g.dart';

/// Whether the C1b post-signup interstitial has been dismissed once
/// (pages.md C1b: first sign-in hands off to it; any exit — either
/// choice card or "Skip for now" — flips the persisted flag so later
/// sign-ins go straight home). The router's auth redirect branches on
/// it; the router primes this provider at boot so the flag is resolved
/// by the time a sign-in evaluates the redirect.
@Riverpod(keepAlive: true)
class FirstActionFlag extends _$FirstActionFlag {
  @override
  Future<bool> build() =>
      ref.watch(persistenceServiceProvider).readFirstActionSeen();

  Future<void> markSeen() async {
    await ref.read(persistenceServiceProvider).writeFirstActionSeen();
    state = const AsyncData<bool>(true);
  }
}
