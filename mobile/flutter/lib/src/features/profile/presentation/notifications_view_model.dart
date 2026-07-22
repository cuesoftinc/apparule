import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/features/profile/domain/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_view_model.g.dart';

/// The MI-16 Orders-tab badge — unread order-kind notifications; C10
/// clears it by marking everything read.
@riverpod
Future<int> ordersTabBadge(Ref ref) =>
    ref.watch(notificationRepositoryProvider).unreadOrderCount();

/// C10's ViewModel — the activity list. Opening the sheet marks all rows
/// read in the REPOSITORY (persisting for the session) without touching
/// the loaded snapshot, so unread tints stay visible for this visit and
/// are gone on the next (the IG read-model).
@riverpod
class NotificationsViewModel extends _$NotificationsViewModel {
  @override
  Future<List<AppNotification>> build() =>
      ref.watch(notificationRepositoryProvider).notifications();

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidate(ordersTabBadgeProvider);
  }

  /// C10 swipe-to-clear.
  Future<void> clear(String id) async {
    await ref.read(notificationRepositoryProvider).remove(id);
    if (state.value case final current?) {
      state = AsyncData(<AppNotification>[
        for (final notification in current)
          if (notification.id != id) notification,
      ]);
    }
    ref.invalidate(ordersTabBadgeProvider);
  }
}
