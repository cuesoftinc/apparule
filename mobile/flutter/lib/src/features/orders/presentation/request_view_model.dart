import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/orders/domain/order.dart';
import 'package:apparule/src/features/orders/presentation/orders_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'request_view_model.g.dart';

/// What C5 orchestrates: the requested post, the vault sessions the
/// snapshot picker offers (C6/C7 integration), and the §6.3 delivery
/// pre-fill from the most recent order.
typedef RequestContext = ({
  Post post,
  List<MeasurementSession> sessions,
  DeliveryAddress? lastDelivery,
});

/// C5's ViewModel — the one place three repositories meet (ViewModels
/// orchestrate; repositories never reference each other,
/// mobile-implementation.md §3). Submission freezes the picked vault
/// session's values into the order snapshot (order-lifecycle.md §1).
@riverpod
class RequestViewModel extends _$RequestViewModel {
  @override
  Future<RequestContext> build(String postId) async {
    final post = await ref.watch(postRepositoryProvider).post(postId);
    final sessions = await ref
        .watch(measurementRepositoryProvider)
        .vaultSessions();
    final lastDelivery = await ref
        .watch(orderRepositoryProvider)
        .lastDeliveryAddress();
    return (post: post, sessions: sessions, lastDelivery: lastDelivery);
  }

  /// Submits the request; returns the created order (status `requested`,
  /// snapshot frozen) for the success screen's "View order".
  Future<Order> submit({
    required MeasurementSession session,
    required DeliveryAddress delivery,
    String notes = '',
    int? budgetCents,
    DateTime? targetDate,
  }) async {
    final context = await future;
    final post = context.post;
    final order = await ref
        .read(orderRepositoryProvider)
        .submitRequest(
          post: OrderPostSummary(
            id: post.id,
            // The web seed's short-caption idiom: orders carry the caption's
            // leading clause.
            caption: post.caption.split(' — ').first,
            thumbUrl: post.media.first.url,
          ),
          designer: OrderParty(
            id: post.designer.id,
            username: post.designer.username,
            avatarUrl: post.designer.avatarUrl,
          ),
          // The frozen copy — name/value pairs only, exactly what the web
          // store snapshots (later vault changes never mutate the order).
          snapshot: OrderSnapshot(
            method: session.method,
            measuredAt: session.createdAt,
            measurements: <SnapshotMeasurement>[
              for (final measurement in session.measurements)
                SnapshotMeasurement(
                  name: measurement.name,
                  valueCm: measurement.valueCm,
                ),
            ],
          ),
          delivery: delivery,
          notes: notes,
          budgetCents: budgetCents,
          targetDate: targetDate,
        );
    ref.invalidate(ordersViewModelProvider);
    return order;
  }
}
