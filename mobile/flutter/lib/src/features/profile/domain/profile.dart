import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// Optional, self-attested location (X-10 tier 1 — sensitive PII, never
/// logged; data-model.md §2).
@freezed
abstract class ProfileLocation with _$ProfileLocation {
  const factory ProfileLocation({
    required String city,
    required String state,
    required String country,
  }) = _ProfileLocation;
}

/// One consent-ledger line (data-model.md §4; web `ConsentRecord`).
@freezed
abstract class ConsentRecord with _$ConsentRecord {
  const factory ConsentRecord({
    required String document,
    required String version,
    required DateTime acceptedAt,
  }) = _ConsentRecord;
}

/// Per-event notification toggles — the ratified B7-mobile Notifications
/// canvas rows (207:2). Richer than the web's four-key prefs (a canvas
/// iteration the mobile surface carries first); payment receipts and
/// delivery confirmations are always sent and carry no toggle.
@freezed
abstract class NotificationPrefs with _$NotificationPrefs {
  const factory NotificationPrefs({
    @Default(true) bool quotesOrderStatus,
    @Default(true) bool newRequests,
    @Default(true) bool likesComments,
    @Default(false) bool newFollowers,
    @Default(true) bool freshOutfits,
    @Default(true) bool freshnessReminders,
    @Default(false) bool emailDigest,
  }) = _NotificationPrefs;
}

/// Privacy toggles — the B7-mobile Privacy & consent canvas (207:7155):
/// AI processing consent (camera capture requires it; manual entry stays
/// available without) and the nearby-recommendations location use.
@freezed
abstract class PrivacyPrefs with _$PrivacyPrefs {
  const factory PrivacyPrefs({
    @Default(true) bool aiProcessing,
    @Default(true) bool nearbyRecommendations,
  }) = _PrivacyPrefs;
}

/// The signed-in account (C9 own / B7 settings) — the web `Account`
/// entity's mobile shape. Designer/monetization state deliberately lives
/// in the earnings feature's repository (C13/C14 domain), not here —
/// repositories never reference each other (mobile-implementation.md §3).
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    required String displayName,
    required String email,
    String? bio,
    String? avatarUrl,
    ProfileLocation? location,
    @Default(NotificationPrefs()) NotificationPrefs notificationPrefs,
    @Default(PrivacyPrefs()) PrivacyPrefs privacyPrefs,
    @Default(<ConsentRecord>[]) List<ConsentRecord> consent,
    @Default(false) bool deletionPending,
  }) = _Profile;
}
