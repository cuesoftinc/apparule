// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_action_flag.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the C1b post-signup interstitial has been dismissed once
/// (pages.md C1b: first sign-in hands off to it; any exit — either
/// choice card or "Skip for now" — flips the persisted flag so later
/// sign-ins go straight home). The router's auth redirect branches on
/// it; the router primes this provider at boot so the flag is resolved
/// by the time a sign-in evaluates the redirect.

@ProviderFor(FirstActionFlag)
final firstActionFlagProvider = FirstActionFlagProvider._();

/// Whether the C1b post-signup interstitial has been dismissed once
/// (pages.md C1b: first sign-in hands off to it; any exit — either
/// choice card or "Skip for now" — flips the persisted flag so later
/// sign-ins go straight home). The router's auth redirect branches on
/// it; the router primes this provider at boot so the flag is resolved
/// by the time a sign-in evaluates the redirect.
final class FirstActionFlagProvider
    extends $AsyncNotifierProvider<FirstActionFlag, bool> {
  /// Whether the C1b post-signup interstitial has been dismissed once
  /// (pages.md C1b: first sign-in hands off to it; any exit — either
  /// choice card or "Skip for now" — flips the persisted flag so later
  /// sign-ins go straight home). The router's auth redirect branches on
  /// it; the router primes this provider at boot so the flag is resolved
  /// by the time a sign-in evaluates the redirect.
  FirstActionFlagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstActionFlagProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstActionFlagHash();

  @$internal
  @override
  FirstActionFlag create() => FirstActionFlag();
}

String _$firstActionFlagHash() => r'bdd3cba27d669389a35c0d9f13bc62cd570ae045';

/// Whether the C1b post-signup interstitial has been dismissed once
/// (pages.md C1b: first sign-in hands off to it; any exit — either
/// choice card or "Skip for now" — flips the persisted flag so later
/// sign-ins go straight home). The router's auth redirect branches on
/// it; the router primes this provider at boot so the flag is resolved
/// by the time a sign-in evaluates the redirect.

abstract class _$FirstActionFlag extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
