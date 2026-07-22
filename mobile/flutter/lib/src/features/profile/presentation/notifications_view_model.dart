import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/domain/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_view_model.g.dart';

/// The MI-16 Orders-tab badge — unread order-kind notifications; C10
/// clears it by marking everything read.
@riverpod
Future<int> ordersTabBadge(Ref ref) =>
    ref.watch(notificationRepositoryProvider).unreadOrderCount();

/// The viewer's following set — the C10 follow-row trailing morph
/// (NotificationRow contract: trailing Follow button on follow kinds)
/// reads it; `FollowGraphController` invalidates it after a morph so the
/// rows re-derive with every other follow surface.
@riverpod
Future<Set<String>> viewerFollowingSet(Ref ref) async {
  final me = await ref.watch(profileRepositoryProvider).me();
  if (me == null) return const <String>{};
  final following = await ref
      .watch(postRepositoryProvider)
      .followingOf(me.username);
  return <String>{for (final user in following) user.username};
}

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
