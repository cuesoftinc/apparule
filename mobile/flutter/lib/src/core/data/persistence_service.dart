import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'persistence_service.g.dart';

/// Stateless persistence wrapper (mobile-implementation.md §3 services).
///
/// Session tokens live in [FlutterSecureStorage] — never SharedPreferences
/// (§9; the legacy PII-as-session pattern is quarantined, not migrated —
/// CV-2). SharedPreferences carries exactly one surviving concern: the
/// theme preference flag (§11 REWRITE of `persistence.dart`).
class PersistenceService {
  PersistenceService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const String _sessionTokenKey = 'session_token';
  static const String _themeModeKey = 'theme_mode';

  Future<String?> readSessionToken() =>
      _secureStorage.read(key: _sessionTokenKey);

  Future<void> writeSessionToken(String token) =>
      _secureStorage.write(key: _sessionTokenKey, value: token);

  Future<void> clearSessionToken() =>
      _secureStorage.delete(key: _sessionTokenKey);

  /// Persisted theme preference: `light` / `dark` / null (follow system).
  Future<String?> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }

  Future<void> writeThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }
}

@Riverpod(keepAlive: true)
PersistenceService persistenceService(Ref ref) => PersistenceService();
