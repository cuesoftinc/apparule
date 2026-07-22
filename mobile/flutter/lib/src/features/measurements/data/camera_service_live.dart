import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

/// The real hardware camera behind the C6 viewfinder — `camera` plugin
/// (CameraX / AVFoundation), front lens preferred (the §10 flow stands
/// the subject facing their propped-up phone, legacy guide copy).
class CameraServiceLive implements CameraService {
  CameraController? _controller;

  @override
  bool get isReady => _controller?.value.isInitialized ?? false;

  @override
  Future<void> initialize() async {
    if (isReady) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw const CameraPermissionDeniedException();
      final camera = cameras.firstWhere(
        (description) => description.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        // High keeps the short edge ≥ 720px — comfortably above the QC
        // resolution floor (capture-qc.md §1) without max-res payloads;
        // the upload step's ≤2048px client resize (flows/vault.md §1)
        // joins with the API wave.
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      _controller = controller;
    } on CameraException catch (error) {
      // Both plugin spellings of a permission denial map to the one
      // domain exception the screen handles.
      if (error.code == 'CameraAccessDenied' ||
          error.code == 'CameraAccessDeniedWithoutPrompt' ||
          error.code == 'cameraPermission') {
        throw const CameraPermissionDeniedException();
      }
      rethrow;
    }
  }

  @override
  Widget buildPreview({CapturePose pose = CapturePose.front}) {
    // One lens sees both poses — the pose axis matters to the fake only.
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return CameraPreview(controller);
  }

  @override
  Future<CapturePhoto> takePhoto({CapturePose pose = CapturePose.front}) async {
    final controller = _controller;
    if (controller == null) {
      throw StateError('takePhoto() before initialize()');
    }
    final file = await controller.takePicture();
    return CapturePhoto(bytes: await file.readAsBytes());
  }

  @override
  Future<void> release() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }
}
