// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C8's detail ViewModel — every action is a REAL lifecycle transition on
/// the repository (validated against order-lifecycle.md §1); the updated
/// order echoes into this state and invalidates the list so its pill
/// pulses to the new state (MI-14). Lifecycle actions rethrow — the
/// screen wraps them in `runAction` (CLASS 4), so races/double-taps
/// surface as a toast instead of a silent unhandled StateError (D39).

@ProviderFor(OrderDetailViewModel)
final orderDetailViewModelProvider = OrderDetailViewModelFamily._();

/// C8's detail ViewModel — every action is a REAL lifecycle transition on
/// the repository (validated against order-lifecycle.md §1); the updated
/// order echoes into this state and invalidates the list so its pill
/// pulses to the new state (MI-14). Lifecycle actions rethrow — the
/// screen wraps them in `runAction` (CLASS 4), so races/double-taps
/// surface as a toast instead of a silent unhandled StateError (D39).
final class OrderDetailViewModelProvider
    extends $AsyncNotifierProvider<OrderDetailViewModel, OrderDetailState> {
  /// C8's detail ViewModel — every action is a REAL lifecycle transition on
  /// the repository (validated against order-lifecycle.md §1); the updated
  /// order echoes into this state and invalidates the list so its pill
  /// pulses to the new state (MI-14). Lifecycle actions rethrow — the
  /// screen wraps them in `runAction` (CLASS 4), so races/double-taps
  /// surface as a toast instead of a silent unhandled StateError (D39).
  OrderDetailViewModelProvider._({
    required OrderDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDetailViewModelHash();

  @override
  String toString() {
    return r'orderDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrderDetailViewModel create() => OrderDetailViewModel();

  @override
  bool operator ==(Object other) {
    return other is OrderDetailViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDetailViewModelHash() =>
    r'96d190928cf4b55b532a779a8ecd72d64325b3e2';

/// C8's detail ViewModel — every action is a REAL lifecycle transition on
/// the repository (validated against order-lifecycle.md §1); the updated
/// order echoes into this state and invalidates the list so its pill
/// pulses to the new state (MI-14). Lifecycle actions rethrow — the
/// screen wraps them in `runAction` (CLASS 4), so races/double-taps
/// surface as a toast instead of a silent unhandled StateError (D39).

final class OrderDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          OrderDetailViewModel,
          AsyncValue<OrderDetailState>,
          OrderDetailState,
          FutureOr<OrderDetailState>,
          String
        > {
  OrderDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'orderDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// C8's detail ViewModel — every action is a REAL lifecycle transition on
  /// the repository (validated against order-lifecycle.md §1); the updated
  /// order echoes into this state and invalidates the list so its pill
  /// pulses to the new state (MI-14). Lifecycle actions rethrow — the
  /// screen wraps them in `runAction` (CLASS 4), so races/double-taps
  /// surface as a toast instead of a silent unhandled StateError (D39).

  OrderDetailViewModelProvider call(String orderId) =>
      OrderDetailViewModelProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderDetailViewModelProvider';
}

/// C8's detail ViewModel — every action is a REAL lifecycle transition on
/// the repository (validated against order-lifecycle.md §1); the updated
/// order echoes into this state and invalidates the list so its pill
/// pulses to the new state (MI-14). Lifecycle actions rethrow — the
/// screen wraps them in `runAction` (CLASS 4), so races/double-taps
/// surface as a toast instead of a silent unhandled StateError (D39).

abstract class _$OrderDetailViewModel extends $AsyncNotifier<OrderDetailState> {
  late final _$args = ref.$arg as String;
  String get orderId => _$args;

  FutureOr<OrderDetailState> build(String orderId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OrderDetailState>, OrderDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OrderDetailState>, OrderDetailState>,
              AsyncValue<OrderDetailState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
