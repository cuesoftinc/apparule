// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engagement_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The engagement mutation façade (the interaction audit's CLASS 1 lock):
/// every like/save/comment/publish mutation on the post corpus routes
/// through here, and ONLY here — `ref.invalidate` on engagement surfaces
/// outside this façade is banned.
///
/// DECLARED invalidation fan-out — like/save/comment ⇒
///   · [homeFeedViewModelProvider] (C2 feed + rail),
///   · [postDetailViewModelProvider] for the mutated post (C4),
///   · [profileViewModelProvider] (C9 liked/saved grids).
/// DECLARED create fan-out — the C15 publish ⇒
///   · [homeFeedViewModelProvider] (the post leads the author's C2 feed),
///   · [exploreViewModelProvider] (the whole family — C3's recency grid),
///   · [profileViewModelProvider] (the C9 own-profile grid + posts count);
/// no [postDetailViewModelProvider] member exists for a brand-new id.
/// The two-surface contract test pins both lists; extending a fan-out
/// means extending the test.
///
/// Rationale: the shell keeps every branch mounted and Riverpod 3 pauses
/// (never disposes) their subscriptions, so a mutation that invalidates
/// only its own provider leaves sibling tabs stale for the whole session
/// (D01/D33 — the "works in tests, broken on device" class). keepAlive
/// for the ratified orchestration reason: a read-only controller must
/// not unmount its Ref across the repository await.

@ProviderFor(EngagementActions)
final engagementActionsProvider = EngagementActionsProvider._();

/// The engagement mutation façade (the interaction audit's CLASS 1 lock):
/// every like/save/comment/publish mutation on the post corpus routes
/// through here, and ONLY here — `ref.invalidate` on engagement surfaces
/// outside this façade is banned.
///
/// DECLARED invalidation fan-out — like/save/comment ⇒
///   · [homeFeedViewModelProvider] (C2 feed + rail),
///   · [postDetailViewModelProvider] for the mutated post (C4),
///   · [profileViewModelProvider] (C9 liked/saved grids).
/// DECLARED create fan-out — the C15 publish ⇒
///   · [homeFeedViewModelProvider] (the post leads the author's C2 feed),
///   · [exploreViewModelProvider] (the whole family — C3's recency grid),
///   · [profileViewModelProvider] (the C9 own-profile grid + posts count);
/// no [postDetailViewModelProvider] member exists for a brand-new id.
/// The two-surface contract test pins both lists; extending a fan-out
/// means extending the test.
///
/// Rationale: the shell keeps every branch mounted and Riverpod 3 pauses
/// (never disposes) their subscriptions, so a mutation that invalidates
/// only its own provider leaves sibling tabs stale for the whole session
/// (D01/D33 — the "works in tests, broken on device" class). keepAlive
/// for the ratified orchestration reason: a read-only controller must
/// not unmount its Ref across the repository await.
final class EngagementActionsProvider
    extends $NotifierProvider<EngagementActions, void> {
  /// The engagement mutation façade (the interaction audit's CLASS 1 lock):
  /// every like/save/comment/publish mutation on the post corpus routes
  /// through here, and ONLY here — `ref.invalidate` on engagement surfaces
  /// outside this façade is banned.
  ///
  /// DECLARED invalidation fan-out — like/save/comment ⇒
  ///   · [homeFeedViewModelProvider] (C2 feed + rail),
  ///   · [postDetailViewModelProvider] for the mutated post (C4),
  ///   · [profileViewModelProvider] (C9 liked/saved grids).
  /// DECLARED create fan-out — the C15 publish ⇒
  ///   · [homeFeedViewModelProvider] (the post leads the author's C2 feed),
  ///   · [exploreViewModelProvider] (the whole family — C3's recency grid),
  ///   · [profileViewModelProvider] (the C9 own-profile grid + posts count);
  /// no [postDetailViewModelProvider] member exists for a brand-new id.
  /// The two-surface contract test pins both lists; extending a fan-out
  /// means extending the test.
  ///
  /// Rationale: the shell keeps every branch mounted and Riverpod 3 pauses
  /// (never disposes) their subscriptions, so a mutation that invalidates
  /// only its own provider leaves sibling tabs stale for the whole session
  /// (D01/D33 — the "works in tests, broken on device" class). keepAlive
  /// for the ratified orchestration reason: a read-only controller must
  /// not unmount its Ref across the repository await.
  EngagementActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'engagementActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$engagementActionsHash();

  @$internal
  @override
  EngagementActions create() => EngagementActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$engagementActionsHash() => r'6fc986f4bae7b5722bb777ffbb0c36d3467cfd12';

/// The engagement mutation façade (the interaction audit's CLASS 1 lock):
/// every like/save/comment/publish mutation on the post corpus routes
/// through here, and ONLY here — `ref.invalidate` on engagement surfaces
/// outside this façade is banned.
///
/// DECLARED invalidation fan-out — like/save/comment ⇒
///   · [homeFeedViewModelProvider] (C2 feed + rail),
///   · [postDetailViewModelProvider] for the mutated post (C4),
///   · [profileViewModelProvider] (C9 liked/saved grids).
/// DECLARED create fan-out — the C15 publish ⇒
///   · [homeFeedViewModelProvider] (the post leads the author's C2 feed),
///   · [exploreViewModelProvider] (the whole family — C3's recency grid),
///   · [profileViewModelProvider] (the C9 own-profile grid + posts count);
/// no [postDetailViewModelProvider] member exists for a brand-new id.
/// The two-surface contract test pins both lists; extending a fan-out
/// means extending the test.
///
/// Rationale: the shell keeps every branch mounted and Riverpod 3 pauses
/// (never disposes) their subscriptions, so a mutation that invalidates
/// only its own provider leaves sibling tabs stale for the whole session
/// (D01/D33 — the "works in tests, broken on device" class). keepAlive
/// for the ratified orchestration reason: a read-only controller must
/// not unmount its Ref across the repository await.

abstract class _$EngagementActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
