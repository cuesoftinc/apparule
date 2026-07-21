// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_feed_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C2 placeholder ViewModel — watches the abstract post repository;
/// dev/stg overrides supply the fake.

@ProviderFor(HomeFeedViewModel)
final homeFeedViewModelProvider = HomeFeedViewModelProvider._();

/// C2 placeholder ViewModel — watches the abstract post repository;
/// dev/stg overrides supply the fake.
final class HomeFeedViewModelProvider
    extends $AsyncNotifierProvider<HomeFeedViewModel, List<Post>> {
  /// C2 placeholder ViewModel — watches the abstract post repository;
  /// dev/stg overrides supply the fake.
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

String _$homeFeedViewModelHash() => r'f4056cc02738de5c22ddb1023b248b02cb3a6758';

/// C2 placeholder ViewModel — watches the abstract post repository;
/// dev/stg overrides supply the fake.

abstract class _$HomeFeedViewModel extends $AsyncNotifier<List<Post>> {
  FutureOr<List<Post>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Post>>, List<Post>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Post>>, List<Post>>,
              AsyncValue<List<Post>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
