import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_summary.freezed.dart';

/// One C12 list row — the web `UserSummary` shape (mock-ahead-of-contract,
/// pages.md B6 lists): enough for a `UserRow` plus the MI-7 morph state.
@freezed
abstract class UserSummary with _$UserSummary {
  const factory UserSummary({
    required String username,
    required String displayName,
    String? avatarUrl,
    @Default(false) bool verified,
    @Default(false) bool isDesigner,
    @Default(false) bool viewerFollows,
  }) = _UserSummary;
}
