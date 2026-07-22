import 'package:apparule/src/core/data/persistence_service.dart';

/// Hermetic [PersistenceService] for tests: the secure-storage session
/// slot becomes an in-memory field (no platform plugin in widget tests),
/// while the SharedPreferences-backed flags inherit the real
/// implementation over `SharedPreferences.setMockInitialValues`.
///
/// Reusing one instance across two `pump`ed apps simulates a relaunch
/// with persistence intact (the boot-flow suite's cold-start scenarios).
class InMemoryPersistenceService extends PersistenceService {
  /// The persisted session marker — exposed for write/purge assertions.
  String? sessionToken;

  @override
  Future<String?> readSessionToken() async => sessionToken;

  @override
  Future<void> writeSessionToken(String token) async => sessionToken = token;

  @override
  Future<void> clearSessionToken() async => sessionToken = null;
}
