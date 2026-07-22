import 'dart:async';
import 'dart:typed_data';

import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/camera_service_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/measurement_exception.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/presentation/vault_view_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_view_model.freezed.dart';
part 'capture_view_model.g.dart';

/// Height bounds (flows/vault.md §1: 100–230 cm ↔ 39–91 in).
const double kMinHeightCm = 100;
const double kMaxHeightCm = 230;

/// The C6 state machine (mobile-implementation.md §10): height → camera
/// (countdown) → processing → results | qc-fail, with the
/// permission-denied dead end resolving to manual entry.
enum CaptureStep { height, camera, processing, qcFail, results, permission }

@freezed
abstract class CaptureState with _$CaptureState {
  const factory CaptureState({
    @Default(CaptureStep.height) CaptureStep step,

    /// Height is canonical cm; the unit is a display preference (MI-13).
    double? heightCm,
    @Default(MeasureUnit.cm) MeasureUnit unit,
    @Default(false) bool heightInvalid,

    /// The camera acquired and previewing.
    @Default(false) bool cameraReady,

    /// Non-null while the 3-2-1 runs (MI-12).
    CountdownCount? countdown,

    /// The captured frame — the processing constellation draws over it.
    Uint8List? photoBytes,

    /// The `pending_save` result (results step).
    MeasurementSession? session,

    /// First-failure-only QC wire code (qc-fail step).
    String? qcFailCode,
    @Default(false) bool saving,

    /// Save landed — the screen routes to the vault (C7).
    @Default(false) bool saved,
  }) = _CaptureState;
}

/// C6's ViewModel (1:1 with `CaptureScreen`) — owns the capture session
/// flow; navigation stays the View's job.
@riverpod
class CaptureViewModel extends _$CaptureViewModel {
  Timer? _countdownTimer;

  /// Dispose-safe mirrors of the pending/saved state — Riverpod forbids
  /// touching `ref`/`state` inside onDispose, so the cleanup closure
  /// captures these fields and the service instances instead.
  String? _pendingSessionId;
  bool _sessionSaved = false;

  @override
  CaptureState build() {
    final camera = ref.watch(cameraServiceProvider);
    final repository = ref.watch(measurementRepositoryProvider);
    ref.onDispose(() {
      _countdownTimer?.cancel();
      // Leaving without saving purges the pending session ("Retake
      // discards" semantics, flows/vault.md §1) and releases the camera.
      if (_pendingSessionId case final pending? when !_sessionSaved) {
        unawaited(repository.discardSession(pending));
      }
      unawaited(camera.release());
    });
    // Microtask, not a direct call: once the seed asset is cached the
    // repository resolves through SynchronousFutures, and the prefill
    // would otherwise assign state while build() is still running.
    unawaited(Future<void>.microtask(_prefillHeight));
    return const CaptureState();
  }

  Future<void> _prefillHeight() async {
    final height = await ref
        .read(measurementRepositoryProvider)
        .lastInputHeightCm();
    if (!ref.mounted || height == null) return;
    if (state.heightCm != null) return;
    state = state.copyWith(heightCm: height);
  }

  void setHeight(double? heightCm) {
    state = state.copyWith(heightCm: heightCm, heightInvalid: false);
  }

  void setUnit(MeasureUnit unit) {
    state = state.copyWith(unit: unit);
  }

  /// Validates the height step (100–230 cm hard gate — unlike manual
  /// entry's advisory ranges, an implausible scale input breaks every
  /// output) and acquires the camera.
  Future<void> continueToCamera() async {
    final height = state.heightCm;
    if (height == null || height < kMinHeightCm || height > kMaxHeightCm) {
      state = state.copyWith(heightInvalid: true);
      return;
    }
    state = state.copyWith(step: CaptureStep.camera, heightInvalid: false);
    try {
      await ref.read(cameraServiceProvider).initialize();
      if (!ref.mounted) return;
      state = state.copyWith(cameraReady: true);
    } on CameraPermissionDeniedException {
      if (!ref.mounted) return;
      state = state.copyWith(step: CaptureStep.permission);
    }
  }

  /// Shutter: runs the 3-2-1 (MI-12), then captures and submits.
  void startCountdown() {
    if (state.countdown != null || state.step != CaptureStep.camera) return;
    state = state.copyWith(countdown: CountdownCount.three);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      switch (state.countdown) {
        case CountdownCount.three:
          state = state.copyWith(countdown: CountdownCount.two);
        case CountdownCount.two:
          state = state.copyWith(countdown: CountdownCount.one);
        case CountdownCount.one || null:
          timer.cancel();
          unawaited(_captureAndSubmit());
      }
    });
  }

  Future<void> _captureAndSubmit() async {
    final camera = ref.read(cameraServiceProvider);
    final photo = await camera.takePhoto();
    if (!ref.mounted) return;
    state = state.copyWith(
      step: CaptureStep.processing,
      countdown: null,
      photoBytes: photo.bytes,
    );
    try {
      final session = await ref
          .read(measurementRepositoryProvider)
          .submitCapture(photo: photo, userHeightCm: state.heightCm!);
      _pendingSessionId = session.id;
      if (!ref.mounted) return;
      state = state.copyWith(step: CaptureStep.results, session: session);
    } on CaptureQcException catch (error) {
      if (!ref.mounted) return;
      // First failure only — the repository already reports exactly one
      // code (capture-qc.md reporting rule).
      state = state.copyWith(step: CaptureStep.qcFail, qcFailCode: error.code);
    }
  }

  /// "Retake" (results quiet action / qc-fail primary): purges any
  /// pending session immediately and returns to the viewfinder.
  Future<void> retake() async {
    if (state.session case final pending?) {
      await ref.read(measurementRepositoryProvider).discardSession(pending.id);
      _pendingSessionId = null;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      step: CaptureStep.camera,
      photoBytes: null,
      session: null,
      qcFailCode: null,
    );
  }

  /// "Save to vault" — flips the pending session `complete`; the View
  /// routes to C7 on [CaptureState.saved].
  Future<void> save() async {
    final session = state.session;
    if (session == null || state.saving) return;
    state = state.copyWith(saving: true);
    await ref.read(measurementRepositoryProvider).saveSession(session.id);
    _sessionSaved = true;
    // The vault list is stale now — rebuild C7 over the grown store.
    ref.invalidate(vaultViewModelProvider);
    if (!ref.mounted) return;
    state = state.copyWith(saving: false, saved: true);
  }

  /// Dev-flavor QC selector (documented seam, mobile-implementation.md
  /// §10): points the fake camera at a `capture_samples.json` scenario so
  /// every capture-qc.md fail code is reproducible on demand. No-op over
  /// the live camera.
  void selectDevSample(String sampleId) {
    final camera = ref.read(cameraServiceProvider);
    if (camera is CameraServiceFake) camera.sampleId = sampleId;
  }
}
