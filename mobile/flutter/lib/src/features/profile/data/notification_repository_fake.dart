import 'package:apparule/src/core/data/fail_next_seam.dart';
import 'package:apparule/src/core/data/seed_json.dart';
import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/features/profile/domain/app_notification.dart';
import 'package:flutter/services.dart';

/// Seed-backed fake (mobile-implementation.md §6): every notification
/// kind, part unread, verbatim from the web mock seed — filtered to the
/// signed-in audience exactly like the web store's `notificationsFor`
/// (an account sees its `acc-*` rows; a designer additionally their
/// `des-*` rows). Read/clear are real mutations that persist for the
/// provider's keepAlive lifetime.
class NotificationRepositoryFake
    with FailNextSeam
    implements NotificationRepository {
  /// [audienceIds] scopes the seed to a viewer — defaults to the §6 test
  /// user; tests pass `{'des-tunde'}` to walk the designer-side rows.
  NotificationRepositoryFake({
    AssetBundle? bundle,
    DateTime Function()? now,
    this.audienceIds = const <String>{'acc-kiki'},
  }) : _bundle = bundle ?? PlatformAssetBundle(),
       _now = now ?? DateTime.now;

  static const String _asset = 'assets/seed/dev/notifications.json';

  final AssetBundle _bundle;
  final DateTime Function() _now;
  final Set<String> audienceIds;

  /// The one in-flight load — concurrent first callers (two providers
  /// watching one keepAlive fake) must all await the SAME parse instead
  /// of the second reading half-loaded state; once loaded, callers get
  /// a fresh completed future built in THEIR zone, so a fake
  /// pre-arranged inside `tester.runAsync` never hands the FakeAsync
  /// test zone a future pinned to another zone (both are profile-wave
  /// findings — the same trap as the C6 rootBundle string cache).
  bool _loaded = false;
  Future<void>? _loading;
  final List<AppNotification> _notifications = <AppNotification>[];

  Future<void> _ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= () async {
      await _load();
      _loaded = true;
    }();
  }

  Future<void> _load() async {
    final now = _now();
    if (await loadSeedJson(_bundle, _asset) case final seed?) {
      for (final entry in seed['notifications'] as List<dynamic>) {
        final json = entry as Map<String, dynamic>;
        if (!audienceIds.contains(json['account_id'] as String)) continue;
        final actor = json['actor'] as Map<String, dynamic>;
        final readDaysAgo = json['read_days_ago'] as num?;
        _notifications.add(
          AppNotification(
            id: json['id'] as String,
            kind: NotificationKind.fromWireName(json['kind'] as String),
            payloadRef: json['payload_ref'] as String,
            text: json['text'] as String,
            actorUsername: actor['username'] as String,
            actorAvatarUrl: actor['avatar_url'] as String?,
            thumbUrl: json['thumb_url'] as String?,
            readAt: readDaysAgo == null ? null : seedDaysAgo(now, readDaysAgo),
            createdAt: switch (json['created_hours_ago'] as num?) {
              final hours? => seedHoursAgo(now, hours),
              null => seedDaysAgo(now, json['created_days_ago'] as num),
            },
          ),
        );
      }
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  Future<List<AppNotification>> notifications() async {
    await _ensureLoaded();
    return List<AppNotification>.unmodifiable(_notifications);
  }

  @override
  Future<void> markAllRead() async {
    await _ensureLoaded();
    maybeFailNext();
    final now = _now();
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].unread) {
        _notifications[i] = _notifications[i].copyWith(readAt: now);
      }
    }
  }

  @override
  Future<void> remove(String id) async {
    await _ensureLoaded();
    maybeFailNext();
    _notifications.removeWhere((notification) => notification.id == id);
  }

  @override
  Future<int> unreadOrderCount() async {
    await _ensureLoaded();
    return _notifications
        .where(
          (notification) =>
              notification.unread && notification.kind.isOrderKind,
        )
        .length;
  }
}
