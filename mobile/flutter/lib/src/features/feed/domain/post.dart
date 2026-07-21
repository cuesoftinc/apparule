import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';

/// Minimal placeholder domain model — fields grow with the screens wave
/// (mobile-implementation.md §6 posts seed).
@freezed
abstract class Post with _$Post {
  const factory Post({required String id}) = _Post;
}
