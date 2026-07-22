// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The MI-16 Orders-tab badge — unread order-kind notifications; C10
/// clears it by marking everything read.

@ProviderFor(ordersTabBadge)
final ordersTabBadgeProvider = OrdersTabBadgeProvider._();

/// The MI-16 Orders-tab badge — unread order-kind notifications; C10
/// clears it by marking everything read.

final class OrdersTabBadgeProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// The MI-16 Orders-tab badge — unread order-kind notifications; C10
  /// clears it by marking everything read.
  OrdersTabBadgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersTabBadgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersTabBadgeHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return ordersTabBadge(ref);
  }
}

String _$ordersTabBadgeHash() => r'694c595a052e46a13e9eebc3898913ddf5ebd4f5';

/// The viewer's following set — the C10 follow-row trailing morph
/// (NotificationRow contract: trailing Follow button on follow kinds)
/// reads it; `FollowGraphController` invalidates it after a morph so the
/// rows re-derive with every other follow surface.

@ProviderFor(viewerFollowingSet)
final viewerFollowingSetProvider = ViewerFollowingSetProvider._();

/// The viewer's following set — the C10 follow-row trailing morph
/// (NotificationRow contract: trailing Follow button on follow kinds)
/// reads it; `FollowGraphController` invalidates it after a morph so the
/// rows re-derive with every other follow surface.

final class ViewerFollowingSetProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// The viewer's following set — the C10 follow-row trailing morph
  /// (NotificationRow contract: trailing Follow button on follow kinds)
  /// reads it; `FollowGraphController` invalidates it after a morph so the
  /// rows re-derive with every other follow surface.
  ViewerFollowingSetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewerFollowingSetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewerFollowingSetHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return viewerFollowingSet(ref);
  }
}

String _$viewerFollowingSetHash() =>
    r'107e1e886b902316de9fe347fe9cf0104191a2e7';

/// C10's ViewModel — the activity list. Opening the sheet marks all rows
/// read in the REPOSITORY (persisting for the session) without touching
/// the loaded snapshot, so unread tints stay visible for this visit and
/// are gone on the next (the IG read-model).

@ProviderFor(NotificationsViewModel)
final notificationsViewModelProvider = NotificationsViewModelProvider._();

/// C10's ViewModel — the activity list. Opening the sheet marks all rows
/// read in the REPOSITORY (persisting for the session) without touching
/// the loaded snapshot, so unread tints stay visible for this visit and
/// are gone on the next (the IG read-model).
final class NotificationsViewModelProvider
    extends
        $AsyncNotifierProvider<NotificationsViewModel, List<AppNotification>> {
  /// C10's ViewModel — the activity list. Opening the sheet marks all rows
  /// read in the REPOSITORY (persisting for the session) without touching
  /// the loaded snapshot, so unread tints stay visible for this visit and
  /// are gone on the next (the IG read-model).
  NotificationsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsViewModelHash();

  @$internal
  @override
  NotificationsViewModel create() => NotificationsViewModel();
}

String _$notificationsViewModelHash() =>
    r'86b299800c0ed604446e162a8f20d52a9957a200';

/// C10's ViewModel — the activity list. Opening the sheet marks all rows
/// read in the REPOSITORY (persisting for the session) without touching
/// the loaded snapshot, so unread tints stay visible for this visit and
/// are gone on the next (the IG read-model).

abstract class _$NotificationsViewModel
    extends $AsyncNotifier<List<AppNotification>> {
  FutureOr<List<AppNotification>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AppNotification>>, List<AppNotification>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AppNotification>>,
                List<AppNotification>
              >,
              AsyncValue<List<AppNotification>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
