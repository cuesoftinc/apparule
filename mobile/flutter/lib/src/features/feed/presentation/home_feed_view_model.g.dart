// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_feed_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C2's ViewModel — feed + story rail off the post repository; like/save
/// and story-seen calls are repository mutations echoed back into state
/// (MI-1/2/3/8 over real fake-state changes).

@ProviderFor(HomeFeedViewModel)
final homeFeedViewModelProvider = HomeFeedViewModelProvider._();

/// C2's ViewModel — feed + story rail off the post repository; like/save
/// and story-seen calls are repository mutations echoed back into state
/// (MI-1/2/3/8 over real fake-state changes).
final class HomeFeedViewModelProvider
    extends $AsyncNotifierProvider<HomeFeedViewModel, HomeFeedState> {
  /// C2's ViewModel — feed + story rail off the post repository; like/save
  /// and story-seen calls are repository mutations echoed back into state
  /// (MI-1/2/3/8 over real fake-state changes).
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

String _$homeFeedViewModelHash() => r'dde8acdb27f48198b01a68945e6a326ed394d222';

/// C2's ViewModel — feed + story rail off the post repository; like/save
/// and story-seen calls are repository mutations echoed back into state
/// (MI-1/2/3/8 over real fake-state changes).

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
