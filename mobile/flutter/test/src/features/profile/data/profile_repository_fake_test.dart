import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seeded account fake: me.json's web-Account fields plus REAL
/// mutations — edits, pref toggles, the deletion request, the export
/// bundle (mobile-implementation.md §6).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProfileRepositoryFake fake() =>
      ProfileRepositoryFake(now: () => DateTime.utc(2026, 7, 22, 12));

  group('seed narrative (web parity)', () {
    test('me() carries the acc-kiki account block', () async {
      final me = await fake().me();

      expect(me, isNotNull);
      expect(me!.id, 'acc-kiki');
      expect(me.username, 'kiki.adeyemi');
      expect(me.displayName, 'Kiki Adeyemi');
      expect(me.email, 'kiki.adeyemi@example.com');
      expect(me.bio, 'aso-ebi sets & bridal');
      expect(me.location?.city, 'Lagos');
      expect(me.deletionPending, isFalse);
    });

    test('notification prefs seed the canvas toggle states (207:2)', () async {
      final me = await fake().me();
      final prefs = me!.notificationPrefs;

      expect(prefs.quotesOrderStatus, isTrue);
      expect(prefs.newRequests, isTrue);
      expect(prefs.likesComments, isTrue);
      expect(prefs.newFollowers, isFalse);
      expect(prefs.freshOutfits, isTrue);
      expect(prefs.freshnessReminders, isTrue);
      expect(prefs.emailDigest, isFalse);
    });

    test('consent ledger derives instants from the pinned clock', () async {
      final me = await fake().me();

      expect(me!.consent, hasLength(2));
      expect(
        me.consent.map((record) => record.document),
        containsAll(<String>['tos', 'privacy']),
      );
      // accepted_days_ago: 40 off 2026-07-22 → 2026-06-12.
      expect(me.consent.first.acceptedAt, DateTime.utc(2026, 6, 12, 12));
    });
  });

  group('mutations persist for the instance lifetime', () {
    test('updateMe edits display fields and the optional location', () async {
      final repository = fake();
      await repository.updateMe(
        displayName: 'Kiki A.',
        bio: 'bridal only',
        location: const ProfileLocation(
          city: 'Ikeja',
          state: 'Lagos',
          country: 'NG',
        ),
      );
      final me = await repository.me();

      expect(me!.displayName, 'Kiki A.');
      expect(me.bio, 'bridal only');
      expect(me.location?.city, 'Ikeja');

      await repository.updateMe(clearLocation: true);
      expect((await repository.me())!.location, isNull);
    });

    test('setNotificationPrefs persists the toggle set', () async {
      final repository = fake();
      final me = await repository.me();
      await repository.setNotificationPrefs(
        me!.notificationPrefs.copyWith(emailDigest: true),
      );

      expect(
        (await repository.me())!.notificationPrefs.emailDigest,
        isTrue,
      );
    });

    test('setPrivacyPrefs persists the AI/nearby consents', () async {
      final repository = fake();
      final me = await repository.me();
      await repository.setPrivacyPrefs(
        me!.privacyPrefs.copyWith(aiProcessing: false),
      );

      expect((await repository.me())!.privacyPrefs.aiProcessing, isFalse);
    });

    test('requestDeletion flips the account to deletion-pending', () async {
      final repository = fake();
      final updated = await repository.requestDeletion();

      expect(updated.deletionPending, isTrue);
      expect((await repository.me())!.deletionPending, isTrue);
    });

    test('exportData bundles the account + consent records', () async {
      final repository = fake();
      final export = await repository.exportData();
      final account = export['account']! as Map<String, Object?>;

      expect(account['username'], 'kiki.adeyemi');
      expect(account['email'], 'kiki.adeyemi@example.com');
      expect(export['consent'], hasLength(2));
      expect(export['generated_at'], isNotNull);
    });
  });
}
