import 'package:apparule/src/features/profile/data/notification_repository_fake.dart';
import 'package:apparule/src/features/profile/domain/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seeded notification fake: audience filtering, read-state
/// persistence, swipe-to-clear, and the MI-16 badge derivation
/// (web notificationsFor/markNotificationsRead parity).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NotificationRepositoryFake fake({
    Set<String> audienceIds = const <String>{'acc-kiki'},
  }) => NotificationRepositoryFake(
    now: () => DateTime.utc(2026, 7, 22, 12),
    audienceIds: audienceIds,
  );

  test('kiki sees her six rows, newest first, three unread', () async {
    final notifications = await fake().notifications();

    expect(notifications, hasLength(6));
    expect(notifications.first.id, 'ntf-4'); // 36 minutes ago
    expect(notifications.where((n) => n.unread), hasLength(3));
    // The designer-audience rows never leak into her sheet.
    expect(
      notifications.map((n) => n.id),
      isNot(contains('ntf-payout-bisi')),
    );
  });

  test('the MI-16 Orders badge counts unread ORDER kinds only', () async {
    final repository = fake();
    // Unread: ntf-quote (order kind) + ntf-2/ntf-4 (social likes).
    expect(await repository.unreadOrderCount(), 1);
  });

  test('markAllRead persists — the next read has no unread rows and no '
      'badge', () async {
    final repository = fake();
    await repository.markAllRead();

    final notifications = await repository.notifications();
    expect(notifications.where((n) => n.unread), isEmpty);
    expect(await repository.unreadOrderCount(), 0);
  });

  test('remove clears a row (C10 swipe-to-clear)', () async {
    final repository = fake();
    await repository.remove('ntf-4');
    final notifications = await repository.notifications();
    expect(notifications, hasLength(5));
    expect(notifications.map((n) => n.id), isNot(contains('ntf-4')));
  });

  test('a designer audience sees the designer-side rows (role-switch '
      'seam)', () async {
    final notifications = await fake(
      audienceIds: <String>{'des-tunde'},
    ).notifications();

    expect(
      notifications.map((n) => n.id).toSet(),
      <String>{'ntf-request-tunde', 'ntf-follow-tunde'},
    );
    expect(
      notifications.map((n) => n.kind).toSet(),
      <NotificationKind>{
        NotificationKind.statusChange,
        NotificationKind.follow,
      },
    );
  });
}
