import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_session.freezed.dart';

/// Session lifecycle (flows/vault.md §1): a capture result exists as
/// `pending_save` until "Save to vault" flips it `complete`; "Retake"
/// purges it.
enum SessionStatus {
  pendingSave('pending_save'),
  complete('complete');

  const SessionStatus(this.wireName);

  /// The flows/vault.md wire name.
  final String wireName;

  static SessionStatus fromWireName(String name) => values.firstWhere(
    (status) => status.wireName == name,
    orElse: () => SessionStatus.complete,
  );
}

/// One measurement row (data-model.md MEASUREMENT; capture-qc.md §4).
@freezed
abstract class Measurement with _$Measurement {
  const factory Measurement({
    required String id,
    required String name,
    required double valueCm,

    /// Per-measurement confidence (capture-qc.md §4) — `< 0.7` renders
    /// the low-confidence chip; manual entries carry `null` (human truth
    /// isn't scored).
    double? confidence,

    /// Wire provenance (`pipeline` / `manual_correction`, api.md §2) —
    /// carried for shape parity; the UI's scan/manual axis derives from
    /// the session method.
    @Default('pipeline') String source,
  }) = _Measurement;
}

/// A measurement session (data-model.md; web mock seed parity) — the C6
/// capture result and the C7 vault row share this shape.
@freezed
abstract class MeasurementSession with _$MeasurementSession {
  const factory MeasurementSession({
    required String id,

    /// Wire method identifier: `mediapipe_2d_v2` (current pipeline,
    /// capture-qc.md §3), `manual`, or historical `mediapipe_2d` — kept
    /// as the wire string because the set is additive by design (§10:
    /// the SMPL method joins without rework).
    required String method,
    required SessionStatus status,
    required List<Measurement> measurements,
    required DateTime createdAt,

    /// The height the session froze (`user_height_cm`, api.md
    /// `POST /measure`); changing your height never retro-scales old
    /// sessions (flows/vault.md §1). Manual sessions may omit it.
    double? inputHeightCm,
  }) = _MeasurementSession;

  const MeasurementSession._();

  /// The manual-entry method (MI-13) — drives the scan/manual card axis.
  bool get isManual => method == 'manual';
}
