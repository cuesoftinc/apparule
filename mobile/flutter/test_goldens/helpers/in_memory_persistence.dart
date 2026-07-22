import 'package:apparule/src/core/data/persistence_service.dart';

/// Hermetic [PersistenceService] for golden scenarios: the secure-storage
/// session slot becomes an in-memory field (no platform plugin in widget
/// tests); the SharedPreferences-backed flags inherit the real
/// implementation. Mirrors `test/helpers/in_memory_persistence.dart`
/// (the two test roots keep their own helper copies).
class InMemoryPersistenceService extends PersistenceService {
  /// The persisted session marker.
  String? sessionToken;

  /// Seed-fake engagement overlay slots — in-memory so the default
  /// `PostRepositoryFake` (persistence seam bound in di.dart) never
  /// touches SharedPreferences in golden scenarios.
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
