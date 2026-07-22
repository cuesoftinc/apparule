import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_rail_entry.freezed.dart';

/// One story-rail avatar (C2, MI-8) — a followed designer, ring lit while
/// they have <48h posts the viewer hasn't opened (web `storyDesignersOf`
/// parity plus the mobile seen-state mutation).
@freezed
abstract class StoryRailEntry with _$StoryRailEntry {
  const factory StoryRailEntry({
    required String username,
    required String newestPostId,

    /// Gradient ring: fresh (<48h) content the viewer hasn't seen yet.
    required bool unseen,
    String? avatarUrl,
  }) = _StoryRailEntry;
}
