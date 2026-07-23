// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C3's ViewModel — a family over the search/filter tuple (the screen
/// owns the controls; each combination is one derivation off the post
/// repository, so mutations elsewhere re-rank honestly on invalidate).

@ProviderFor(exploreViewModel)
final exploreViewModelProvider = ExploreViewModelFamily._();

/// C3's ViewModel — a family over the search/filter tuple (the screen
/// owns the controls; each combination is one derivation off the post
/// repository, so mutations elsewhere re-rank honestly on invalidate).

final class ExploreViewModelProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExploreResults>,
          ExploreResults,
          FutureOr<ExploreResults>
        >
    with $FutureModifier<ExploreResults>, $FutureProvider<ExploreResults> {
  /// C3's ViewModel — a family over the search/filter tuple (the screen
  /// owns the controls; each combination is one derivation off the post
  /// repository, so mutations elsewhere re-rank honestly on invalidate).
  ExploreViewModelProvider._({
    required ExploreViewModelFamily super.from,
    required ({String query, String? tag, bool nearMe}) super.argument,
  }) : super(
         retry: null,
         name: r'exploreViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exploreViewModelHash();

  @override
  String toString() {
    return r'exploreViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ExploreResults> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExploreResults> create(Ref ref) {
    final argument =
        this.argument as ({String query, String? tag, bool nearMe});
    return exploreViewModel(
      ref,
      query: argument.query,
      tag: argument.tag,
      nearMe: argument.nearMe,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExploreViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exploreViewModelHash() => r'75e321d2954437ae2a1cd198033aba8a605f4a77';

/// C3's ViewModel — a family over the search/filter tuple (the screen
/// owns the controls; each combination is one derivation off the post
/// repository, so mutations elsewhere re-rank honestly on invalidate).

final class ExploreViewModelFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ExploreResults>,
          ({String query, String? tag, bool nearMe})
        > {
  ExploreViewModelFamily._()
    : super(
        retry: null,
        name: r'exploreViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// C3's ViewModel — a family over the search/filter tuple (the screen
  /// owns the controls; each combination is one derivation off the post
  /// repository, so mutations elsewhere re-rank honestly on invalidate).

  ExploreViewModelProvider call({
    String query = '',
    String? tag,
    bool nearMe = true,
  }) => ExploreViewModelProvider._(
    argument: (query: query, tag: tag, nearMe: nearMe),
    from: this,
  );

  @override
  String toString() => r'exploreViewModelProvider';
}
