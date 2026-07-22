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

/// The profile-surface MI-7 morph (C9 public header + C12 rows) — one
/// mutation path into the social graph, then every derivation that
/// renders follow state re-derives: the C12 lists, the C9 headers (own
/// counts + public morph), and C3's sections (ViewModel-to-ViewModel
/// invalidation is the ratified orchestration idiom — the repository
/// stays the single source of truth). keepAlive for the same reason as
/// ExploreFollowController: read-only orchestration must not unmount its
/// Ref across the repository await.

@ProviderFor(FollowGraphController)
final followGraphControllerProvider = FollowGraphControllerProvider._();

/// The profile-surface MI-7 morph (C9 public header + C12 rows) — one
/// mutation path into the social graph, then every derivation that
/// renders follow state re-derives: the C12 lists, the C9 headers (own
/// counts + public morph), and C3's sections (ViewModel-to-ViewModel
/// invalidation is the ratified orchestration idiom — the repository
/// stays the single source of truth). keepAlive for the same reason as
/// ExploreFollowController: read-only orchestration must not unmount its
/// Ref across the repository await.
final class FollowGraphControllerProvider
    extends $NotifierProvider<FollowGraphController, void> {
  /// The profile-surface MI-7 morph (C9 public header + C12 rows) — one
  /// mutation path into the social graph, then every derivation that
  /// renders follow state re-derives: the C12 lists, the C9 headers (own
  /// counts + public morph), and C3's sections (ViewModel-to-ViewModel
  /// invalidation is the ratified orchestration idiom — the repository
  /// stays the single source of truth). keepAlive for the same reason as
  /// ExploreFollowController: read-only orchestration must not unmount its
  /// Ref across the repository await.
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
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$followGraphControllerHash() =>
    r'50af046a490bd5860693f799aa09de76a877c235';

/// The profile-surface MI-7 morph (C9 public header + C12 rows) — one
/// mutation path into the social graph, then every derivation that
/// renders follow state re-derives: the C12 lists, the C9 headers (own
/// counts + public morph), and C3's sections (ViewModel-to-ViewModel
/// invalidation is the ratified orchestration idiom — the repository
/// stays the single source of truth). keepAlive for the same reason as
/// ExploreFollowController: read-only orchestration must not unmount its
/// Ref across the repository await.

abstract class _$FollowGraphController extends $Notifier<void> {
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
