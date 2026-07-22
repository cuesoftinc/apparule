// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_list_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C12's list derivation — one family instance per (username, tab); the
/// controller below invalidates the whole family after a morph so both
/// tabs re-derive from the mutated graph.

@ProviderFor(followList)
final followListProvider = FollowListFamily._();

/// C12's list derivation — one family instance per (username, tab); the
/// controller below invalidates the whole family after a morph so both
/// tabs re-derive from the mutated graph.

final class FollowListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserSummary>>,
          List<UserSummary>,
          FutureOr<List<UserSummary>>
        >
    with
        $FutureModifier<List<UserSummary>>,
        $FutureProvider<List<UserSummary>> {
  /// C12's list derivation — one family instance per (username, tab); the
  /// controller below invalidates the whole family after a morph so both
  /// tabs re-derive from the mutated graph.
  FollowListProvider._({
    required FollowListFamily super.from,
    required ({String username, FollowListKind kind}) super.argument,
  }) : super(
         retry: null,
         name: r'followListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followListHash();

  @override
  String toString() {
    return r'followListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<UserSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserSummary>> create(Ref ref) {
    final argument = this.argument as ({String username, FollowListKind kind});
    return followList(ref, username: argument.username, kind: argument.kind);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followListHash() => r'6f11809494684c4b3980871c6b4a04e77cc8e796';

/// C12's list derivation — one family instance per (username, tab); the
/// controller below invalidates the whole family after a morph so both
/// tabs re-derive from the mutated graph.

final class FollowListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<UserSummary>>,
          ({String username, FollowListKind kind})
        > {
  FollowListFamily._()
    : super(
        retry: null,
        name: r'followListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// C12's list derivation — one family instance per (username, tab); the
  /// controller below invalidates the whole family after a morph so both
  /// tabs re-derive from the mutated graph.

  FollowListProvider call({
    required String username,
    required FollowListKind kind,
  }) => FollowListProvider._(
    argument: (username: username, kind: kind),
    from: this,
  );

  @override
  String toString() => r'followListProvider';
}

/// The MI-7 follow morph façade — optimistic by construction (the
/// interaction audit's CLASS 1 + CLASS 2 locks): ONE mutation path into
/// the social graph, and `ref.invalidate` on follow surfaces outside
/// this façade is banned.
///
/// State is the viewer's local follow OVERLAY (`username → follows`):
/// [setFollow] flips it SYNCHRONOUSLY — watching rows morph this frame,
/// never after a round-trip (D18/D19/D58) — then reconciles with the
/// repository. Failure rolls the overlay back and rethrows so callers
/// toast via `runAction`. Surfaces render
/// `overlay[username] ?? serverValue`.
///
/// DECLARED invalidation fan-out — follow/unfollow ⇒
///   · [followListProvider] (C12 lists, whole family),
///   · [publicProfileViewModelProvider] (C9 public headers),
///   · [profileViewModelProvider] (C9 own counts),
///   · [exploreViewModelProvider] (C3 sections),
///   · [viewerFollowingSetProvider] (C10 rows),
///   · [homeFeedViewModelProvider] (D02: the mounted Home branch must
///     re-derive — new follows' posts/rings appear without a restart).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// keepAlive: the overlay is session truth and the Ref must not unmount
/// across the repository await.

@ProviderFor(FollowGraphController)
final followGraphControllerProvider = FollowGraphControllerProvider._();

/// The MI-7 follow morph façade — optimistic by construction (the
/// interaction audit's CLASS 1 + CLASS 2 locks): ONE mutation path into
/// the social graph, and `ref.invalidate` on follow surfaces outside
/// this façade is banned.
///
/// State is the viewer's local follow OVERLAY (`username → follows`):
/// [setFollow] flips it SYNCHRONOUSLY — watching rows morph this frame,
/// never after a round-trip (D18/D19/D58) — then reconciles with the
/// repository. Failure rolls the overlay back and rethrows so callers
/// toast via `runAction`. Surfaces render
/// `overlay[username] ?? serverValue`.
///
/// DECLARED invalidation fan-out — follow/unfollow ⇒
///   · [followListProvider] (C12 lists, whole family),
///   · [publicProfileViewModelProvider] (C9 public headers),
///   · [profileViewModelProvider] (C9 own counts),
///   · [exploreViewModelProvider] (C3 sections),
///   · [viewerFollowingSetProvider] (C10 rows),
///   · [homeFeedViewModelProvider] (D02: the mounted Home branch must
///     re-derive — new follows' posts/rings appear without a restart).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// keepAlive: the overlay is session truth and the Ref must not unmount
/// across the repository await.
final class FollowGraphControllerProvider
    extends $NotifierProvider<FollowGraphController, Map<String, bool>> {
  /// The MI-7 follow morph façade — optimistic by construction (the
  /// interaction audit's CLASS 1 + CLASS 2 locks): ONE mutation path into
  /// the social graph, and `ref.invalidate` on follow surfaces outside
  /// this façade is banned.
  ///
  /// State is the viewer's local follow OVERLAY (`username → follows`):
  /// [setFollow] flips it SYNCHRONOUSLY — watching rows morph this frame,
  /// never after a round-trip (D18/D19/D58) — then reconciles with the
  /// repository. Failure rolls the overlay back and rethrows so callers
  /// toast via `runAction`. Surfaces render
  /// `overlay[username] ?? serverValue`.
  ///
  /// DECLARED invalidation fan-out — follow/unfollow ⇒
  ///   · [followListProvider] (C12 lists, whole family),
  ///   · [publicProfileViewModelProvider] (C9 public headers),
  ///   · [profileViewModelProvider] (C9 own counts),
  ///   · [exploreViewModelProvider] (C3 sections),
  ///   · [viewerFollowingSetProvider] (C10 rows),
  ///   · [homeFeedViewModelProvider] (D02: the mounted Home branch must
  ///     re-derive — new follows' posts/rings appear without a restart).
  /// The two-surface contract test pins this list; extending the fan-out
  /// means extending the test.
  ///
  /// keepAlive: the overlay is session truth and the Ref must not unmount
  /// across the repository await.
  FollowGraphControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'followGraphControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$followGraphControllerHash();

  @$internal
  @override
  FollowGraphController create() => FollowGraphController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$followGraphControllerHash() =>
    r'99b4ca30db8f506c47f12810856b66d1439fadbd';

/// The MI-7 follow morph façade — optimistic by construction (the
/// interaction audit's CLASS 1 + CLASS 2 locks): ONE mutation path into
/// the social graph, and `ref.invalidate` on follow surfaces outside
/// this façade is banned.
///
/// State is the viewer's local follow OVERLAY (`username → follows`):
/// [setFollow] flips it SYNCHRONOUSLY — watching rows morph this frame,
/// never after a round-trip (D18/D19/D58) — then reconciles with the
/// repository. Failure rolls the overlay back and rethrows so callers
/// toast via `runAction`. Surfaces render
/// `overlay[username] ?? serverValue`.
///
/// DECLARED invalidation fan-out — follow/unfollow ⇒
///   · [followListProvider] (C12 lists, whole family),
///   · [publicProfileViewModelProvider] (C9 public headers),
///   · [profileViewModelProvider] (C9 own counts),
///   · [exploreViewModelProvider] (C3 sections),
///   · [viewerFollowingSetProvider] (C10 rows),
///   · [homeFeedViewModelProvider] (D02: the mounted Home branch must
///     re-derive — new follows' posts/rings appear without a restart).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// keepAlive: the overlay is session truth and the Ref must not unmount
/// across the repository await.

abstract class _$FollowGraphController extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
