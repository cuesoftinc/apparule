import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_detail_view_model.g.dart';

/// C4's ViewModel — one post. Like/save route through the
/// `EngagementActions` façade, whose declared fan-out invalidates this
/// family instance alongside C2 and the C9 grids (CLASS 1); the screen's
/// value-preserving body switch keeps the rendered post through the
/// rebuild (CLASS 2).
@riverpod
class PostDetailViewModel extends _$PostDetailViewModel {
  @override
  Future<Post> build(String postId) =>
      ref.watch(postRepositoryProvider).post(postId);
}
