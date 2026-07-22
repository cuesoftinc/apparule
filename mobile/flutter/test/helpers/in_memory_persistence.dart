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

  /// The seed-fake engagement overlay slots — in-memory fields so the
  /// default `PostRepositoryFake` (which binds the persistence seam via
  /// di.dart) never touches SharedPreferences in tests that don't mock
  /// it. Reusing one instance across two pumps simulates the restart the
  /// engagement-persistence contract test asserts.
  List<String>? fakeLikedPostIds;
  List<String>? fakeSavedPostIds;
  List<String>? fakeFollows;

  @override
  Future<String?> readSessionToken() async => sessionToken;

  @override
  Future<void> writeSessionToken(String token) async => sessionToken = token;

  @override
  Future<void> clearSessionToken() async => sessionToken = null;

  @override
  Future<({List<String>? liked, List<String>? saved, List<String>? follows})>
  readFakeEngagement() async => (
    liked: fakeLikedPostIds,
    saved: fakeSavedPostIds,
    follows: fakeFollows,
  );

  @override
  Future<void> writeFakeLikedPostIds(List<String> ids) async =>
      fakeLikedPostIds = ids;

  @override
  Future<void> writeFakeSavedPostIds(List<String> ids) async =>
      fakeSavedPostIds = ids;

  @override
  Future<void> writeFakeFollows(List<String> usernames) async =>
      fakeFollows = usernames;
}
