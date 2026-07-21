import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_repository.g.dart';

/// Abstract post/social-graph repository — C2/C3/C4/C11 all operate over
/// this one domain (mobile-implementation.md §3).
abstract class PostRepository {
  /// The home-feed posts (C2).
  Future<List<Post>> homeFeed();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) => throw UnimplementedError(
  'postRepository must be overridden with a *Fake or *Remote '
  'implementation (mobile-implementation.md §6)',
);
