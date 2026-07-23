// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engagement_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The engagement mutation façade (the interaction audit's CLASS 1 lock):
/// every like/save/comment mutation routes through here, and ONLY here —
/// `ref.invalidate` on engagement surfaces outside this façade is banned.
///
/// DECLARED invalidation fan-out — like/save/comment ⇒
///   · [homeFeedViewModelProvider] (C2 feed + rail),
///   · [postDetailViewModelProvider] for the mutated post (C4),
///   · [profileViewModelProvider] (C9 liked/saved grids).
/// The two-surface contract test pins this list; extending the fan-out
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
/// every like/save/comment mutation routes through here, and ONLY here —
/// `ref.invalidate` on engagement surfaces outside this façade is banned.
///
/// DECLARED invalidation fan-out — like/save/comment ⇒
///   · [homeFeedViewModelProvider] (C2 feed + rail),
///   · [postDetailViewModelProvider] for the mutated post (C4),
///   · [profileViewModelProvider] (C9 liked/saved grids).
/// The two-surface contract test pins this list; extending the fan-out
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
  /// every like/save/comment mutation routes through here, and ONLY here —
  /// `ref.invalidate` on engagement surfaces outside this façade is banned.
  ///
  /// DECLARED invalidation fan-out — like/save/comment ⇒
  ///   · [homeFeedViewModelProvider] (C2 feed + rail),
  ///   · [postDetailViewModelProvider] for the mutated post (C4),
  ///   · [profileViewModelProvider] (C9 liked/saved grids).
  /// The two-surface contract test pins this list; extending the fan-out
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

String _$engagementActionsHash() => r'1e04b897ef6711f2eb639b49a8d8823a5e5a9411';

/// The engagement mutation façade (the interaction audit's CLASS 1 lock):
/// every like/save/comment mutation routes through here, and ONLY here —
/// `ref.invalidate` on engagement surfaces outside this façade is banned.
///
/// DECLARED invalidation fan-out — like/save/comment ⇒
///   · [homeFeedViewModelProvider] (C2 feed + rail),
///   · [postDetailViewModelProvider] for the mutated post (C4),
///   · [profileViewModelProvider] (C9 liked/saved grids).
/// The two-surface contract test pins this list; extending the fan-out
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
