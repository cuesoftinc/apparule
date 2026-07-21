// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).

@ProviderFor(postRepository)
final postRepositoryProvider = PostRepositoryProvider._();

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).

final class PostRepositoryProvider
    extends $FunctionalProvider<PostRepository, PostRepository, PostRepository>
    with $Provider<PostRepository> {
  /// Overridden per entrypoint (di.dart) — no default implementation exists
  /// until the API wave lands `*Remote` (mobile-implementation.md §6).
  PostRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postRepositoryHash();

  @$internal
  @override
  $ProviderElement<PostRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PostRepository create(Ref ref) {
    return postRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostRepository>(value),
    );
  }
}

String _$postRepositoryHash() => r'c6603799269b666fd21cd1e97f7f58c543873383';
