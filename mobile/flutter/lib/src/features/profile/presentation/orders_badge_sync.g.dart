// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_badge_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// MI-16 (D22): the Orders-tab badge clears on TAB VISIT, not only when
/// C10 marks everything read — web DashboardShell parity (it marks
/// order-kind notifications read whenever the Orders tab is active and
/// the badge is non-zero). The shell calls [markVisited] from its badge
/// effect; only order-kind rows flip, so social unreads survive for C10.
///
/// keepAlive: the controller fires from a post-frame callback with no
/// watcher — an autoDispose lifecycle would tear the Ref down mid-mark.

@ProviderFor(OrdersBadgeSync)
final ordersBadgeSyncProvider = OrdersBadgeSyncProvider._();

/// MI-16 (D22): the Orders-tab badge clears on TAB VISIT, not only when
/// C10 marks everything read — web DashboardShell parity (it marks
/// order-kind notifications read whenever the Orders tab is active and
/// the badge is non-zero). The shell calls [markVisited] from its badge
/// effect; only order-kind rows flip, so social unreads survive for C10.
///
/// keepAlive: the controller fires from a post-frame callback with no
/// watcher — an autoDispose lifecycle would tear the Ref down mid-mark.
final class OrdersBadgeSyncProvider
    extends $NotifierProvider<OrdersBadgeSync, void> {
  /// MI-16 (D22): the Orders-tab badge clears on TAB VISIT, not only when
  /// C10 marks everything read — web DashboardShell parity (it marks
  /// order-kind notifications read whenever the Orders tab is active and
  /// the badge is non-zero). The shell calls [markVisited] from its badge
  /// effect; only order-kind rows flip, so social unreads survive for C10.
  ///
  /// keepAlive: the controller fires from a post-frame callback with no
  /// watcher — an autoDispose lifecycle would tear the Ref down mid-mark.
  OrdersBadgeSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersBadgeSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersBadgeSyncHash();

  @$internal
  @override
  OrdersBadgeSync create() => OrdersBadgeSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$ordersBadgeSyncHash() => r'c68c3142e9331cd37f7f51d7b09c15c007f241be';

/// MI-16 (D22): the Orders-tab badge clears on TAB VISIT, not only when
/// C10 marks everything read — web DashboardShell parity (it marks
/// order-kind notifications read whenever the Orders tab is active and
/// the badge is non-zero). The shell calls [markVisited] from its badge
/// effect; only order-kind rows flip, so social unreads survive for C10.
///
/// keepAlive: the controller fires from a post-frame callback with no
/// watcher — an autoDispose lifecycle would tear the Ref down mid-mark.

abstract class _$OrdersBadgeSync extends $Notifier<void> {
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
