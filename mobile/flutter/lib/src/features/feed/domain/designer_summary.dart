import 'package:freezed_annotation/freezed_annotation.dart';

part 'designer_summary.freezed.dart';

/// A designer row in explore search results (web `UserSummary` parity —
/// pages.md B2/C3 sectioned results).
@freezed
abstract class DesignerSummary with _$DesignerSummary {
  const factory DesignerSummary({
    required String username,
    required String displayName,

    /// "City, State" meta line (canvas: "Amara Okafor · Lagos Island"
    /// composes display name · locality).
    required String locality,
    String? avatarUrl,
    @Default(false) bool verified,

    /// MI-7 Follow/Following morph state for the signed-in viewer.
    @Default(false) bool viewerFollows,
  }) = _DesignerSummary;
}
