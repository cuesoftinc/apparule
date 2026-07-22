import 'package:apparule/src/features/feed/domain/designer_summary.dart';
import 'package:apparule/src/features/feed/domain/post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'explore_results.freezed.dart';

/// C3 explore payload — the browse grid, or sectioned search results
/// (Designers above Outfits, pages.md B2/C3 search-results state).
@freezed
abstract class ExploreResults with _$ExploreResults {
  const factory ExploreResults({
    required List<Post> posts,

    /// Non-empty only for query searches (the Designers section).
    @Default(<DesignerSummary>[]) List<DesignerSummary> designers,
  }) = _ExploreResults;
}
