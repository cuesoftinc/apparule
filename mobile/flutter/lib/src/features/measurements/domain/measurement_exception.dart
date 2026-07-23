import 'package:apparule/src/core/utils/capture_pose.dart';

/// A capture rejected by QC (capture-qc.md §1–2): [code] is the wire fail
/// code from the `422 {error: {code, message, guidance, pose}}` envelope
/// (flows/vault.md §1) — the FIRST failing check in table order **within
/// the failing pose**, never a list. QC is per pose (M-10): [pose] names
/// which photo failed, the client re-enters that pose's camera only, and
/// an accepted pose is never discarded. Presentation maps [code] 1:1 onto
/// `QcFailCode` for the QCHintChip's canonical guidance copy
/// (`arms_position` copy is pose-contextual).
class CaptureQcException implements Exception {
  const CaptureQcException(this.code, {required this.pose});

  /// Wire fail code, e.g. `not_frontal` / `not_side_profile`.
  final String code;

  /// The failing pose — the retake re-enters this pose's camera.
  final CapturePose pose;

  @override
  String toString() => 'CaptureQcException($code, pose: ${pose.wireName})';
}
