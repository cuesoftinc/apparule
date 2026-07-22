import 'package:apparule/src/core/data/seed_json.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:flutter/services.dart';

/// Seed-backed fake (mobile-implementation.md §6): the me.json account
/// fields (web `Account` entity parity — email, bio, prefs, consent
/// ledger), with real mutations: edits, pref toggles, and the deletion
/// request all persist for the provider's keepAlive lifetime, so the B7
/// banner state survives navigation the way the web mock's PATCH does.
class ProfileRepositoryFake implements ProfileRepository {
  ProfileRepositoryFake({AssetBundle? bundle, DateTime Function()? now})
    // Instance-scoped bundle, never the global rootBundle — its string
    // cache pins futures to the zone that first loaded them, which
    // deadlocks later widget tests (C6 wave finding).
    : _bundle = bundle ?? PlatformAssetBundle(),
      _now = now ?? DateTime.now;

  static const String _meAsset = 'assets/seed/dev/me.json';

  final AssetBundle _bundle;
  final DateTime Function() _now;

  bool _loaded = false;
  Profile? _me;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final now = _now();
    if (await loadSeedJson(_bundle, _meAsset) case final me?) {
      _me = Profile(
        id: me['id'] as String,
        username: me['username'] as String,
        displayName: me['display_name'] as String,
        email: me['email'] as String? ?? '',
        bio: me['bio'] as String?,
        avatarUrl: me['avatar_url'] as String?,
        location: switch (me['profile_location']) {
          final Map<String, dynamic> location => ProfileLocation(
            city: location['city'] as String,
            state: location['state'] as String,
            country: location['country'] as String,
          ),
          _ => null,
        },
        notificationPrefs: switch (me['notification_prefs']) {
          final Map<String, dynamic> prefs => NotificationPrefs(
            quotesOrderStatus: prefs['quotes_order_status'] as bool? ?? true,
            newRequests: prefs['new_requests'] as bool? ?? true,
            likesComments: prefs['likes_comments'] as bool? ?? true,
            newFollowers: prefs['new_followers'] as bool? ?? false,
            freshOutfits: prefs['fresh_outfits'] as bool? ?? true,
            freshnessReminders: prefs['freshness_reminders'] as bool? ?? true,
            emailDigest: prefs['email_digest'] as bool? ?? false,
          ),
          _ => const NotificationPrefs(),
        },
        privacyPrefs: switch (me['privacy_prefs']) {
          final Map<String, dynamic> prefs => PrivacyPrefs(
            aiProcessing: prefs['ai_processing'] as bool? ?? true,
            nearbyRecommendations:
                prefs['nearby_recommendations'] as bool? ?? true,
          ),
          _ => const PrivacyPrefs(),
        },
        consent: <ConsentRecord>[
          for (final entry in (me['consent'] as List<dynamic>? ??
              const <dynamic>[]))
            ConsentRecord(
              document: (entry as Map<String, dynamic>)['document'] as String,
              version: entry['version'] as String,
              acceptedAt: seedDaysAgo(
                now,
                entry['accepted_days_ago'] as num,
              ),
            ),
        ],
        deletionPending: me['deletion_state'] == 'deletion_pending',
      );
    }
  }

  Profile get _loadedMe {
    final me = _me;
    if (me == null) throw StateError('No signed-in profile seeded');
    return me;
  }

  @override
  Future<Profile?> me() async {
    await _ensureLoaded();
    return _me;
  }

  @override
  Future<Profile> updateMe({
    String? displayName,
    String? bio,
    ProfileLocation? location,
    bool clearLocation = false,
  }) async {
    await _ensureLoaded();
    final me = _loadedMe;
    _me = me.copyWith(
      displayName: displayName ?? me.displayName,
      bio: bio ?? me.bio,
      location: clearLocation ? null : (location ?? me.location),
    );
    return _loadedMe;
  }

  @override
  Future<Profile> setNotificationPrefs(NotificationPrefs prefs) async {
    await _ensureLoaded();
    _me = _loadedMe.copyWith(notificationPrefs: prefs);
    return _loadedMe;
  }

  @override
  Future<Profile> setPrivacyPrefs(PrivacyPrefs prefs) async {
    await _ensureLoaded();
    _me = _loadedMe.copyWith(privacyPrefs: prefs);
    return _loadedMe;
  }

  @override
  Future<Map<String, Object?>> exportData() async {
    await _ensureLoaded();
    final me = _loadedMe;
    // The web mock's export shape in miniature: the account block plus
    // the §6 domain seeds the real export would bundle (the fake keeps
    // it honest without cross-referencing sibling repositories).
    return <String, Object?>{
      'account': <String, Object?>{
        'id': me.id,
        'username': me.username,
        'display_name': me.displayName,
        'email': me.email,
        'bio': me.bio,
        'profile_location': switch (me.location) {
          final location? => <String, Object?>{
            'city': location.city,
            'state': location.state,
            'country': location.country,
          },
          _ => null,
        },
      },
      'consent': <Object?>[
        for (final record in me.consent)
          <String, Object?>{
            'document': record.document,
            'version': record.version,
            'accepted_at': record.acceptedAt.toIso8601String(),
          },
      ],
      'generated_at': _now().toIso8601String(),
    };
  }

  @override
  Future<Profile> requestDeletion() async {
    await _ensureLoaded();
    _me = _loadedMe.copyWith(deletionPending: true);
    return _loadedMe;
  }
}
