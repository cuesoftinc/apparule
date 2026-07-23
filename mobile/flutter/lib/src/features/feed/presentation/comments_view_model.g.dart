// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C11's ViewModel — a post's comments; posting appends through the
/// `EngagementActions` façade (which keeps count == list at the
/// repository and fans out to C2/C4/C9 — D33), echoing the returned row
/// locally so the sheet never refetches under the composer.

@ProviderFor(CommentsViewModel)
final commentsViewModelProvider = CommentsViewModelFamily._();

/// C11's ViewModel — a post's comments; posting appends through the
/// `EngagementActions` façade (which keeps count == list at the
/// repository and fans out to C2/C4/C9 — D33), echoing the returned row
/// locally so the sheet never refetches under the composer.
final class CommentsViewModelProvider
    extends $AsyncNotifierProvider<CommentsViewModel, List<PostComment>> {
  /// C11's ViewModel — a post's comments; posting appends through the
  /// `EngagementActions` façade (which keeps count == list at the
  /// repository and fans out to C2/C4/C9 — D33), echoing the returned row
  /// locally so the sheet never refetches under the composer.
  CommentsViewModelProvider._({
    required CommentsViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'commentsViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentsViewModelHash();

  @override
  String toString() {
    return r'commentsViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommentsViewModel create() => CommentsViewModel();

  @override
  bool operator ==(Object other) {
    return other is CommentsViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentsViewModelHash() => r'c774e2b3a3f976953cd6c51546741db3d4527ec4';

/// C11's ViewModel — a post's comments; posting appends through the
/// `EngagementActions` façade (which keeps count == list at the
/// repository and fans out to C2/C4/C9 — D33), echoing the returned row
/// locally so the sheet never refetches under the composer.

final class CommentsViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentsViewModel,
          AsyncValue<List<PostComment>>,
          List<PostComment>,
          FutureOr<List<PostComment>>,
          String
        > {
  CommentsViewModelFamily._()
    : super(
        retry: null,
        name: r'commentsViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// C11's ViewModel — a post's comments; posting appends through the
  /// `EngagementActions` façade (which keeps count == list at the
  /// repository and fans out to C2/C4/C9 — D33), echoing the returned row
  /// locally so the sheet never refetches under the composer.

  CommentsViewModelProvider call(String postId) =>
      CommentsViewModelProvider._(argument: postId, from: this);

  @override
  String toString() => r'commentsViewModelProvider';
}

/// C11's ViewModel — a post's comments; posting appends through the
/// `EngagementActions` façade (which keeps count == list at the
/// repository and fans out to C2/C4/C9 — D33), echoing the returned row
/// locally so the sheet never refetches under the composer.

abstract class _$CommentsViewModel extends $AsyncNotifier<List<PostComment>> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  FutureOr<List<PostComment>> build(String postId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PostComment>>, List<PostComment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PostComment>>, List<PostComment>>,
              AsyncValue<List<PostComment>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
