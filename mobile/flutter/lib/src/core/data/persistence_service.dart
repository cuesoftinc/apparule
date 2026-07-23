import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'persistence_service.g.dart';

/// Stateless persistence wrapper (mobile-implementation.md §3 services).
///
/// Session tokens live in [FlutterSecureStorage] — never SharedPreferences
/// (§9; the legacy PII-as-session pattern was retired, never migrated —
/// CV-2). SharedPreferences carries only non-secret UI flags: the theme
/// preference (§11 REWRITE of `persistence.dart`) and the C6
/// guide-completion flag (§10 — the guide turns skippable once completed).
class PersistenceService {
  PersistenceService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const String _sessionTokenKey = 'session_token';
  static const String _themeModeKey = 'theme_mode';
  static const String _captureGuideSeenKey = 'capture_guide_seen';
  static const String _firstActionSeenKey = 'first_action_seen';
  static const String _firstSaveToastKey = 'first_save_toast_shown';
  static const String _recentSearchesKey = 'explore_recent_searches';
  static const String _fakeLikedPostIdsKey = 'fake_liked_post_ids';
  static const String _fakeSavedPostIdsKey = 'fake_saved_post_ids';
  static const String _fakeFollowsKey = 'fake_follows';

  Future<String?> readSessionToken() =>
      _secureStorage.read(key: _sessionTokenKey);

  Future<void> writeSessionToken(String token) =>
      _secureStorage.write(key: _sessionTokenKey, value: token);

  Future<void> clearSessionToken() =>
      _secureStorage.delete(key: _sessionTokenKey);

  /// Persisted theme preference: `light` / `dark` / `system`; null (never
  /// set) also reads as follow-system.
  Future<String?> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }

  Future<void> writeThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  /// Whether the C6 instructional guide has been completed once
  /// (mobile-implementation.md §10: the ➕ entry then goes straight to
  /// capture, and re-entered guides grow a Skip).
  Future<bool> readCaptureGuideSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_captureGuideSeenKey) ?? false;
  }

  Future<void> writeCaptureGuideSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_captureGuideSeenKey, true);
  }

  /// Whether the C1b post-signup interstitial has been dismissed once
  /// (pages.md C1b: "Take your first measurement" / "Explore outfits",
  /// skippable — first sign-in hands off to it, later sign-ins skip it).
  Future<bool> readFirstActionSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstActionSeenKey) ?? false;
  }

  Future<void> writeFirstActionSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstActionSeenKey, true);
  }

  /// Whether the MI-3 first-save toast has ever shown ("Saved to your
  /// looks" — once per install, the web `first-save.ts` localStorage
  /// gate's mobile sibling; saved state itself lives in the repository).
  Future<bool> readFirstSaveToastShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstSaveToastKey) ?? false;
  }

  Future<void> writeFirstSaveToastShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstSaveToastKey, true);
  }

  /// The C3 recent-searches list, newest first, capped at 5 by the
  /// writer (web `apparule.explore.recent` localStorage parity — a local
  /// view preference, never server state).
  Future<List<String>> readRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? const <String>[];
  }

  Future<void> writeRecentSearches(List<String> terms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, terms);
  }

  // -- seed-fake engagement overlay (CLASS 1, D01's restart half) ------------
  //
  // Until the API wave lands `*Remote`, engagement truth lives in
  // `PostRepositoryFake` — these slots persist the viewer's like/save
  // sets and follow list so a restart re-derives the same feed the
  // session mutated. Null (never written) = seed defaults.

  /// The persisted engagement overlay: each list is null until the first
  /// mutation of its set persists it.
  Future<({List<String>? liked, List<String>? saved, List<String>? follows})>
  readFakeEngagement() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      liked: prefs.getStringList(_fakeLikedPostIdsKey),
      saved: prefs.getStringList(_fakeSavedPostIdsKey),
      follows: prefs.getStringList(_fakeFollowsKey),
    );
  }

  Future<void> writeFakeLikedPostIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_fakeLikedPostIdsKey, ids);
  }

  Future<void> writeFakeSavedPostIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_fakeSavedPostIdsKey, ids);
  }

  Future<void> writeFakeFollows(List<String> usernames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_fakeFollowsKey, usernames);
  }
}

@Riverpod(keepAlive: true)
PersistenceService persistenceService(Ref ref) => PersistenceService();
