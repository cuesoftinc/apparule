import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';

/// Empty-state fake — the seeded §6 narrative (assets/seed/) arrives with
/// the screens wave; the interface seam is what this wave establishes.
class PostRepositoryFake implements PostRepository {
  @override
  Future<List<Post>> homeFeed() async => const <Post>[];
}
