/// The two-photo capture's pose axis (M-10, decisions.md): a capture is
/// **front + side (right profile)** photos plus height. Shared the way
/// `MeasureUnit` is — the data layer speaks it (per-pose QC, the 422
/// envelope's `pose` field) and core/ui renders it (CaptureOverlay's
/// silhouette axis, the QCHintChip's pose-contextual `arms_position`
/// copy), so it lives in core/utils rather than either layer.
library;

/// One capture pose (flows/vault.md §1: front → side → processing; a QC
/// retry re-enters the failing pose only, never advancing the counter).
enum CapturePose {
  /// Pose 1 of 2 — frontal, arms slightly out (capture-qc.md §2 front
  /// table).
  front('front'),

  /// Pose 2 of 2 — right profile, arms relaxed (capture-qc.md §2 side
  /// deltas: `not_side_profile` + the arms-relaxed rule).
  side('side');

  const CapturePose(this.wireName);

  /// The flows/vault.md wire name (`422 {error: {…, pose}}`).
  final String wireName;

  /// 1-based pose counter ("Pose 1 of 2" / "Pose 2 of 2", M-9 bar title).
  int get number => index + 1;

  /// Maps a wire name to its pose; defaults to [front] for unknown
  /// values (forward-compatible envelope reading).
  static CapturePose fromWireName(String name) => values.firstWhere(
    (pose) => pose.wireName == name,
    orElse: () => CapturePose.front,
  );
}
