import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_service.g.dart';

/// The user declined (or previously revoked) camera access — C6 renders
/// the camera-permission EmptyState (explainer + settings deep-link +
/// "enter manually instead", flows/vault.md §1 edge cases).
class CameraPermissionDeniedException implements Exception {
  const CameraPermissionDeniedException();
}

/// Stateless-contract camera seam (mobile-implementation.md §3 services):
/// the C6 screen previews and captures through this interface only.
/// `CameraServiceLive` wraps the `camera` plugin (real hardware);
/// `CameraServiceFake` serves the bundled sample frame so simulators, CI,
/// and the dev flavor complete the full capture journey without a camera
/// (§10 TEST_MODE seam).
///
/// The preview is inherently a widget, so this seam — unlike the
/// repositories — exposes one build method; it stays presentation-free
/// otherwise.
abstract class CameraService {
  /// Acquires the (front) camera. Throws
  /// [CameraPermissionDeniedException] when access is denied.
  Future<void> initialize();

  /// Whether [initialize] completed and the preview/capture are usable.
  bool get isReady;

  /// The live viewfinder — fills the CaptureOverlay's 9:16 viewport slot.
  Widget buildPreview();

  /// Captures one frame.
  Future<CapturePhoto> takePhoto();

  /// Releases the camera (screen dispose).
  Future<void> release();
}

/// Overridden per entrypoint (di.dart): fakes carry `CameraServiceFake`;
/// prod swaps in `CameraServiceLive` (hardware is not env-gated the way
/// `*Remote` repositories are — the real viewfinder ships now, the real
/// pipeline with the API wave).
@Riverpod(keepAlive: true)
CameraService cameraService(Ref ref) => throw UnimplementedError(
  'cameraService must be overridden with a live or fake implementation '
  '(mobile-implementation.md §10 TEST_MODE seam)',
);
