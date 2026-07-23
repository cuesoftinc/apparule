// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_feed_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C2's ViewModel — feed + story rail off the post repository. Engagement
/// mutations (like/save/comment) route through the `EngagementActions`
/// façade, whose declared fan-out invalidates this provider (CLASS 1 —
/// `ref.invalidate` on engagement surfaces outside the façade is banned);
/// the screen's value-preserving body switch keeps the rendered list
/// through those rebuilds (CLASS 2).

@ProviderFor(HomeFeedViewModel)
final homeFeedViewModelProvider = HomeFeedViewModelProvider._();

/// C2's ViewModel — feed + story rail off the post repository. Engagement
/// mutations (like/save/comment) route through the `EngagementActions`
/// façade, whose declared fan-out invalidates this provider (CLASS 1 —
/// `ref.invalidate` on engagement surfaces outside the façade is banned);
/// the screen's value-preserving body switch keeps the rendered list
/// through those rebuilds (CLASS 2).
final class HomeFeedViewModelProvider
    extends $AsyncNotifierProvider<HomeFeedViewModel, HomeFeedState> {
  /// C2's ViewModel — feed + story rail off the post repository. Engagement
  /// mutations (like/save/comment) route through the `EngagementActions`
  /// façade, whose declared fan-out invalidates this provider (CLASS 1 —
  /// `ref.invalidate` on engagement surfaces outside the façade is banned);
  /// the screen's value-preserving body switch keeps the rendered list
  /// through those rebuilds (CLASS 2).
  HomeFeedViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeFeedViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeFeedViewModelHash();

  @$internal
  @override
  HomeFeedViewModel create() => HomeFeedViewModel();
}

String _$homeFeedViewModelHash() => r'f54f3b4eb098c9ebdea575982b1db574daff30e2';

/// C2's ViewModel — feed + story rail off the post repository. Engagement
/// mutations (like/save/comment) route through the `EngagementActions`
/// façade, whose declared fan-out invalidates this provider (CLASS 1 —
/// `ref.invalidate` on engagement surfaces outside the façade is banned);
/// the screen's value-preserving body switch keeps the rendered list
/// through those rebuilds (CLASS 2).

abstract class _$HomeFeedViewModel extends $AsyncNotifier<HomeFeedState> {
  FutureOr<HomeFeedState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HomeFeedState>, HomeFeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HomeFeedState>, HomeFeedState>,
              AsyncValue<HomeFeedState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
