import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:apparule/src/features/measurements/domain/measurement_exception.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'measurement_repository.g.dart';

/// Abstract measurement repository — the C6 capture session flow and the
/// C7 vault read/write through it (mobile-implementation.md §10;
/// flows/vault.md §1). The `*Remote` twin lands with the API wave and
/// fronts `POST /customers/me/sessions` (api.md §2) behind the same
/// interface.
abstract class MeasurementRepository {
  /// All saved (`complete`) vault sessions, newest first (C7).
  Future<List<MeasurementSession>> vaultSessions();

  /// The height the newest session froze — pre-fills the per-session
  /// height step (flows/vault.md §1: stored per account; changing it
  /// never retro-scales old sessions).
  Future<double?> lastInputHeightCm();

  /// Submits the two-pose capture + height to the measure pipeline
  /// (api.md `POST /measure`: multipart `image_front` + `image_side` +
  /// `user_height_cm` — both images ride one request, M-10). Resolves to
  /// a `pending_save` session with per-measurement confidence
  /// (capture-qc.md §4); throws [CaptureQcException] naming the FIRST
  /// failing capture-qc.md code **and the failing pose** when QC rejects
  /// a frame — QC is per pose, front table first, and an accepted pose
  /// is never discarded by the other pose's failure.
  Future<MeasurementSession> submitCapture({
    required CapturePhoto front,
    required CapturePhoto side,
    required double userHeightCm,
  });

  /// "Save to vault": flips a pending session `complete` so C7 lists it.
  Future<MeasurementSession> saveSession(String sessionId);

  /// "Retake": purges an unsaved session immediately (flows/vault.md §1).
  Future<void> discardSession(String sessionId);

  /// MI-13 manual entry: tape-measured values (canonical cm) become a
  /// `method: manual` session — `confidence: null`, human truth isn't
  /// scored (capture-qc.md §4). Saves straight into the vault.
  Future<MeasurementSession> saveManualEntry(Map<String, double> valuesCm);

  /// Deletes a saved vault session (the C7 history sheet's per-session
  /// delete, pages.md C7 = B4). Unknown ids are a no-op — deletes are
  /// idempotent.
  Future<void> deleteSession(String sessionId);

  /// Per-session export (features.md F2-9; api.md
  /// `POST /sessions/{id}/exports`) — resolves to the session's CSV
  /// document. The `*Remote` twin requests the served export; the fake
  /// renders the same shape locally.
  Future<String> exportSessionCsv(String sessionId);
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
MeasurementRepository measurementRepository(Ref ref) =>
    throw UnimplementedError(
      'measurementRepository must be overridden with a *Fake or *Remote '
      'implementation (mobile-implementation.md §6)',
    );
