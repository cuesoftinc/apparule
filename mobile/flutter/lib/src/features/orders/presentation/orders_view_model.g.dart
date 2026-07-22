// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C8's list ViewModel — the viewer's orders, both roles, newest
/// activity first (the fake orders by last event).

@ProviderFor(OrdersViewModel)
final ordersViewModelProvider = OrdersViewModelProvider._();

/// C8's list ViewModel — the viewer's orders, both roles, newest
/// activity first (the fake orders by last event).
final class OrdersViewModelProvider
    extends $AsyncNotifierProvider<OrdersViewModel, List<Order>> {
  /// C8's list ViewModel — the viewer's orders, both roles, newest
  /// activity first (the fake orders by last event).
  OrdersViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersViewModelHash();

  @$internal
  @override
  OrdersViewModel create() => OrdersViewModel();
}

String _$ordersViewModelHash() => r'6401e5e93e6a868f7185efc404d09c814554b816';

/// C8's list ViewModel — the viewer's orders, both roles, newest
/// activity first (the fake orders by last event).

abstract class _$OrdersViewModel extends $AsyncNotifier<List<Order>> {
  FutureOr<List<Order>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Order>>, List<Order>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Order>>, List<Order>>,
              AsyncValue<List<Order>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
