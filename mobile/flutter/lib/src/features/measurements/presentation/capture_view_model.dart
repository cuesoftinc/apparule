import 'dart:async';
import 'dart:typed_data';

import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/camera_service_fake.dart';
import 'package:apparule/src/features/measurements/data/capture_sample_catalog.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:apparule/src/features/measurements/domain/measurement_exception.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/presentation/vault_actions.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_view_model.freezed.dart';
part 'capture_view_model.g.dart';

/// Height bounds (flows/vault.md §1: 100–230 cm ↔ 39–91 in).
const double kMinHeightCm = 100;
const double kMaxHeightCm = 230;

/// The searching beat between the viewfinder going live and the 3-2-1
/// arming (QA-convergence ruling: the canvas capture frames carry no
/// shutter — capture is automatic). Over the fake camera this simulates
/// the subject aligning with the silhouette; a live pose-detection
/// alignment signal replaces the timer when the real camera lands (§1
/// phase 4).
const Duration kCaptureAlignDelay = Duration(milliseconds: 1200);

/// The C6 state machine (mobile-implementation.md §10, M-10 two-pose):
/// camera (front, Pose 1 of 2) → camera (side, Pose 2 of 2) → height
/// (when not on file) → processing → results | qc-fail, with the
/// permission-denied dead end resolving to manual entry. A QC retry
/// re-enters the FAILING pose only — the counter never advances on
/// retry, and an accepted pose is never discarded.
enum CaptureStep { camera, height, processing, qcFail, results, permission }

@freezed
abstract class CaptureState with _$CaptureState {
  const factory CaptureState({
    @Default(CaptureStep.camera) CaptureStep step,

    /// The pose the viewfinder is capturing ("Pose 1 of 2"/"Pose 2 of 2"
    /// over-media bar title, M-9).
    @Default(CapturePose.front) CapturePose pose,

    /// The camera acquired and previewing.
    @Default(false) bool cameraReady,

    /// Non-null while the 3-2-1 runs (MI-12).
    CountdownCount? countdown,

    /// Accepted frames — a pose-2 QC failure keeps [frontPhoto] (M-10:
    /// an accepted pose is never discarded; the retake resubmits it
    /// with the fresh side frame).
    CapturePhoto? frontPhoto,
    CapturePhoto? sidePhoto,

    /// Height is canonical cm; the unit is a display preference (MI-13,
    /// inches by default — A-9). Pre-filled from the newest session —
    /// when on file, the height step is skipped (flows/vault.md §1).
    double? heightCm,
    @Default(MeasureUnit.inch) MeasureUnit unit,
    @Default(false) bool heightInvalid,

    /// The `pending_save` result (results step).
    MeasurementSession? session,

    /// First-failure-only QC wire code + its failing pose (qc-fail step).
    String? qcFailCode,
    CapturePose? qcFailPose,
    @Default(false) bool saving,

    /// Save landed — the screen routes to the vault (C7).
    @Default(false) bool saved,
  }) = _CaptureState;

  const CaptureState._();

  /// The frame the full-bleed processing/qc-fail surfaces draw: the
  /// failing pose's photo on qc-fail, the front frame elsewhere.
  Uint8List? get displayBytes => switch (step) {
    CaptureStep.qcFail =>
      (qcFailPose == CapturePose.side ? sidePhoto : frontPhoto)?.bytes,
    _ => frontPhoto?.bytes,
  };
}

/// C6's ViewModel (1:1 with `CaptureScreen`) — owns the two-pose capture
/// session flow; navigation stays the View's job.
@riverpod
class CaptureViewModel extends _$CaptureViewModel {
  Timer? _alignTimer;
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
      _alignTimer?.cancel();
      _countdownTimer?.cancel();
      // Leaving without saving purges the pending session ("Retake
      // discards" semantics, flows/vault.md §1) and releases the camera.
      if (_pendingSessionId case final pending? when !_sessionSaved) {
        unawaited(repository.discardSession(pending));
      }
      unawaited(camera.release());
    });
    // Microtask, not a direct call: the flow starts itself (the two-pose
    // sequence opens on the front viewfinder), and assigning state while
    // build() is still running is forbidden.
    unawaited(Future<void>.microtask(_start));
    return const CaptureState();
  }

  /// Acquires the camera for Pose 1 and pre-fills the account height
  /// (flows/vault.md §1: collected once, stored per account — when on
  /// file the height step is skipped after Pose 2).
  Future<void> _start() async {
    unawaited(_prefillHeight());
    try {
      await ref.read(cameraServiceProvider).initialize();
      if (!ref.mounted) return;
      state = state.copyWith(cameraReady: true);
      _armAutoCapture();
    } on CameraPermissionDeniedException {
      if (!ref.mounted) return;
      state = state.copyWith(step: CaptureStep.permission);
    }
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

  /// Arms the auto-capture: after the [kCaptureAlignDelay] searching
  /// beat the 3-2-1 starts on its own — no shutter exists (pages.md C6
  /// "silhouette overlay + countdown"; the canvas capture frames show no
  /// control layer). Leaving the screen cancels it (provider dispose).
  void _armAutoCapture() {
    _alignTimer?.cancel();
    _alignTimer = Timer(kCaptureAlignDelay, _startCountdown);
  }

  /// Runs the 3-2-1 (MI-12), then captures the current pose on
  /// completion.
  void _startCountdown() {
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
          unawaited(_capturePose());
      }
    });
  }

  /// Captures the current pose's frame, then advances the sequence:
  /// front → side (the counter's ONLY advance), side → height/submit.
  Future<void> _capturePose() async {
    final pose = state.pose;
    final photo = await ref.read(cameraServiceProvider).takePhoto(pose: pose);
    if (!ref.mounted) return;
    switch (pose) {
      case CapturePose.front:
        state = state.copyWith(
          frontPhoto: photo,
          countdown: null,
          pose: CapturePose.side,
        );
        _armAutoCapture();
      case CapturePose.side:
        state = state.copyWith(sidePhoto: photo, countdown: null);
        if (state.heightCm != null) {
          await _submit();
        } else {
          // Height not on file — the §10 height step interposes before
          // the one-request upload.
          state = state.copyWith(step: CaptureStep.height);
        }
    }
  }

  /// Validates the height step (100–230 cm hard gate — unlike manual
  /// entry's advisory ranges, an implausible scale input breaks every
  /// output) and submits the session.
  Future<void> continueFromHeight() async {
    final height = state.heightCm;
    if (height == null || height < kMinHeightCm || height > kMaxHeightCm) {
      state = state.copyWith(heightInvalid: true);
      return;
    }
    state = state.copyWith(heightInvalid: false);
    await _submit();
  }

  /// One request carries both images + height (api.md `POST /measure`:
  /// `image_front` + `image_side` + `user_height_cm`).
  Future<void> _submit() async {
    final front = state.frontPhoto;
    final side = state.sidePhoto;
    if (front == null || side == null) return;
    state = state.copyWith(step: CaptureStep.processing);
    try {
      final session = await ref
          .read(measurementRepositoryProvider)
          .submitCapture(
            front: front,
            side: side,
            userHeightCm: state.heightCm!,
          );
      _pendingSessionId = session.id;
      if (!ref.mounted) return;
      state = state.copyWith(step: CaptureStep.results, session: session);
    } on CaptureQcException catch (error) {
      if (!ref.mounted) return;
      // Per-pose, first-failure-only — the repository already reports
      // exactly one code naming the failing pose (capture-qc.md §2).
      state = state.copyWith(
        step: CaptureStep.qcFail,
        qcFailCode: error.code,
        qcFailPose: error.pose,
      );
    }
  }

  /// QC-fail "Retake": re-enters the FAILING pose's camera only — the
  /// pose counter never advances on retry, and the other pose's accepted
  /// frame is kept (flows/vault.md §1).
  void retakeFailedPose() {
    final pose = state.qcFailPose ?? CapturePose.front;
    state = state.copyWith(
      step: CaptureStep.camera,
      pose: pose,
      frontPhoto: pose == CapturePose.front ? null : state.frontPhoto,
      sidePhoto: pose == CapturePose.side ? null : state.sidePhoto,
      qcFailCode: null,
      qcFailPose: null,
    );
    _armAutoCapture();
  }

  /// Results "Retake" (quiet action): purges the pending session
  /// immediately and restarts the whole two-pose sequence at Pose 1.
  Future<void> retakeSession() async {
    if (state.session case final pending?) {
      await ref.read(measurementRepositoryProvider).discardSession(pending.id);
      _pendingSessionId = null;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      step: CaptureStep.camera,
      pose: CapturePose.front,
      frontPhoto: null,
      sidePhoto: null,
      session: null,
      qcFailCode: null,
      qcFailPose: null,
    );
    _armAutoCapture();
  }

  /// "Save to vault" — flips the pending session `complete` through the
  /// VaultActions façade (its declared fan-out re-derives C7 AND the C9
  /// header's MI-11 freshness ring, D16); the View routes to C7 on
  /// [CaptureState.saved].
  Future<void> save() async {
    final session = state.session;
    if (session == null || state.saving) return;
    state = state.copyWith(saving: true);
    await ref.read(vaultActionsProvider.notifier).saveSession(session.id);
    _sessionSaved = true;
    if (!ref.mounted) return;
    state = state.copyWith(saving: false, saved: true);
  }

  /// Dev-flavor QC selector (documented seam, mobile-implementation.md
  /// §10): points the fake camera's [CaptureSample.pose] frame at a
  /// `capture_samples.json` scenario so every capture-qc.md fail code —
  /// both poses' tables — is reproducible on demand. No-op over the live
  /// camera.
  void selectDevSample(CaptureSample sample) {
    final camera = ref.read(cameraServiceProvider);
    if (camera is! CameraServiceFake) return;
    switch (sample.pose) {
      case CapturePose.front:
        camera.frontSampleId = sample.id;
      case CapturePose.side:
        camera.sideSampleId = sample.id;
    }
  }
}
