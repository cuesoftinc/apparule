// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C4's ViewModel — one post. Like/save route through the
/// `EngagementActions` façade, whose declared fan-out invalidates this
/// family instance alongside C2 and the C9 grids (CLASS 1); the screen's
/// value-preserving body switch keeps the rendered post through the
/// rebuild (CLASS 2).

@ProviderFor(PostDetailViewModel)
final postDetailViewModelProvider = PostDetailViewModelFamily._();

/// C4's ViewModel — one post. Like/save route through the
/// `EngagementActions` façade, whose declared fan-out invalidates this
/// family instance alongside C2 and the C9 grids (CLASS 1); the screen's
/// value-preserving body switch keeps the rendered post through the
/// rebuild (CLASS 2).
final class PostDetailViewModelProvider
    extends $AsyncNotifierProvider<PostDetailViewModel, Post> {
  /// C4's ViewModel — one post. Like/save route through the
  /// `EngagementActions` façade, whose declared fan-out invalidates this
  /// family instance alongside C2 and the C9 grids (CLASS 1); the screen's
  /// value-preserving body switch keeps the rendered post through the
  /// rebuild (CLASS 2).
  PostDetailViewModelProvider._({
    required PostDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'postDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postDetailViewModelHash();

  @override
  String toString() {
    return r'postDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PostDetailViewModel create() => PostDetailViewModel();

  @override
  bool operator ==(Object other) {
    return other is PostDetailViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postDetailViewModelHash() =>
    r'1d2a6a57ce36b049b449244cb57ff5a4b854ed94';

/// C4's ViewModel — one post. Like/save route through the
/// `EngagementActions` façade, whose declared fan-out invalidates this
/// family instance alongside C2 and the C9 grids (CLASS 1); the screen's
/// value-preserving body switch keeps the rendered post through the
/// rebuild (CLASS 2).

final class PostDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          PostDetailViewModel,
          AsyncValue<Post>,
          Post,
          FutureOr<Post>,
          String
        > {
  PostDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'postDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// C4's ViewModel — one post. Like/save route through the
  /// `EngagementActions` façade, whose declared fan-out invalidates this
  /// family instance alongside C2 and the C9 grids (CLASS 1); the screen's
  /// value-preserving body switch keeps the rendered post through the
  /// rebuild (CLASS 2).

  PostDetailViewModelProvider call(String postId) =>
      PostDetailViewModelProvider._(argument: postId, from: this);

  @override
  String toString() => r'postDetailViewModelProvider';
}

/// C4's ViewModel — one post. Like/save route through the
/// `EngagementActions` façade, whose declared fan-out invalidates this
/// family instance alongside C2 and the C9 grids (CLASS 1); the screen's
/// value-preserving body switch keeps the rendered post through the
/// rebuild (CLASS 2).

abstract class _$PostDetailViewModel extends $AsyncNotifier<Post> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  FutureOr<Post> build(String postId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Post>, Post>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Post>, Post>,
              AsyncValue<Post>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
