import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/features/profile/presentation/notifications_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orders_badge_sync.g.dart';

/// MI-16 (D22): the Orders-tab badge clears on TAB VISIT, not only when
/// C10 marks everything read — web DashboardShell parity (it marks
/// order-kind notifications read whenever the Orders tab is active and
/// the badge is non-zero). The shell calls [markVisited] from its badge
/// effect; only order-kind rows flip, so social unreads survive for C10.
@riverpod
class OrdersBadgeSync extends _$OrdersBadgeSync {
  bool _marking = false;

  @override
  void build() {}

  /// Marks order-kind notifications read and re-derives the badge.
  /// Re-entrant calls (the shell effect can fire per frame while the
  /// mark is in flight) collapse into the one in-flight mark.
  Future<void> markVisited() async {
    if (_marking) return;
    _marking = true;
    try {
      await ref.read(notificationRepositoryProvider).markOrderKindsRead();
      ref.invalidate(ordersTabBadgeProvider);
    } finally {
      _marking = false;
    }
  }
}
