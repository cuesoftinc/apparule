import 'package:apparule/src/core/data/persistence_service.dart';

/// Hermetic [PersistenceService] for golden scenarios: the secure-storage
/// session slot becomes an in-memory field (no platform plugin in widget
/// tests); the SharedPreferences-backed flags inherit the real
/// implementation. Mirrors `test/helpers/in_memory_persistence.dart`
/// (the two test roots keep their own helper copies).
class InMemoryPersistenceService extends PersistenceService {
  /// The persisted session marker.
  String? sessionToken;

  @override
  Future<String?> readSessionToken() async => sessionToken;

  @override
  Future<void> writeSessionToken(String token) async => sessionToken = token;

  @override
  Future<void> clearSessionToken() async => sessionToken = null;
}
