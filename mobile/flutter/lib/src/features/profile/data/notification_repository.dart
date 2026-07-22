import 'package:apparule/src/features/profile/domain/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_repository.g.dart';

/// Abstract notification repository — C10 sits in the profile feature
/// (mobile-implementation.md §3: its entry point is the profile tab's
/// bell affordance / the C2 top-bar bell). Read state is a REAL mutation
/// that persists for the session (the web `/notifications/read` seam).
abstract class NotificationRepository {
  /// The signed-in user's activity, newest first (SOC-008).
  Future<List<AppNotification>> notifications();

  /// Marks everything read — opening C10 clears the unread state the
  /// next visit renders (and the MI-16 Orders-tab badge).
  Future<void> markAllRead();

  /// C10 swipe-to-clear.
  Future<void> remove(String id);

  /// Unread order-kind rows — the MI-16 Orders tab badge count.
  Future<int> unreadOrderCount();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    throw UnimplementedError(
      'notificationRepository must be overridden with a *Fake or *Remote '
      'implementation (mobile-implementation.md §6)',
    );
