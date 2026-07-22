import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

/// Notification kinds (SOC-008; web `Notification.kind` parity).
enum NotificationKind {
  quote('quote'),
  comment('comment'),
  like('like'),
  follow('follow'),
  statusChange('status_change'),
  payout('payout');

  const NotificationKind(this.wireName);

  final String wireName;

  static NotificationKind fromWireName(String name) =>
      values.firstWhere((kind) => kind.wireName == name);

  /// Order-related kinds badge the Orders tab (MI-16) and deep-link into
  /// C8; social kinds link into the feed surfaces.
  bool get isOrderKind => switch (this) {
    NotificationKind.quote ||
    NotificationKind.statusChange ||
    NotificationKind.payout => true,
    NotificationKind.comment ||
    NotificationKind.like ||
    NotificationKind.follow => false,
  };
}

/// One activity-sheet row (pages.md C10; web mock seed parity).
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationKind kind,

    /// The order/post id the row deep-links to.
    required String payloadRef,
    required String text,
    required String actorUsername,
    required DateTime createdAt,
    String? actorAvatarUrl,
    String? thumbUrl,

    /// `null` = unread (tinted row + dot).
    DateTime? readAt,
  }) = _AppNotification;

  const AppNotification._();

  bool get unread => readAt == null;
}
