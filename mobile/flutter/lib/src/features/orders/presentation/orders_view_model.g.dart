// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C8 placeholder ViewModel — watches the abstract order repository;
/// flavor overrides supply the fake.

@ProviderFor(OrdersViewModel)
final ordersViewModelProvider = OrdersViewModelProvider._();

/// C8 placeholder ViewModel — watches the abstract order repository;
/// flavor overrides supply the fake.
final class OrdersViewModelProvider
    extends $AsyncNotifierProvider<OrdersViewModel, List<Order>> {
  /// C8 placeholder ViewModel — watches the abstract order repository;
  /// flavor overrides supply the fake.
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

String _$ordersViewModelHash() => r'caef7f92d330533af59dca523577d5a67c1c6a03';

/// C8 placeholder ViewModel — watches the abstract order repository;
/// flavor overrides supply the fake.

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
