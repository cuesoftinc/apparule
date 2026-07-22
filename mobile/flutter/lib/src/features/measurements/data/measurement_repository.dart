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

  /// Submits one frontal photo + height to the measure pipeline
  /// (api.md `POST /measure`: `image` + `user_height_cm`). Resolves to a
  /// `pending_save` session with per-measurement confidence
  /// (capture-qc.md §4); throws [CaptureQcException] with the FIRST
  /// failing capture-qc.md code when QC rejects the frame.
  Future<MeasurementSession> submitCapture({
    required CapturePhoto photo,
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
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
MeasurementRepository measurementRepository(Ref ref) =>
    throw UnimplementedError(
      'measurementRepository must be overridden with a *Fake or *Remote '
      'implementation (mobile-implementation.md §6)',
    );
