import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/capture_sample_catalog.dart';
import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The §10 TEST_MODE camera: previews and captures the bundled sample
/// frames — the frontal photograph for Pose 1 and the neutral dark side
/// frame for Pose 2 (canvas 540:9224: no side-pose sample photo exists) —
/// so simulators, CI, and the dev flavor run the full two-pose C6 journey
/// without hardware. [frontSampleId]/[sideSampleId] select which QC
/// scenario each pose's captured photo carries (`capture_samples.json`);
/// the capture screen's dev-flavor selector swaps them per pose, and
/// `MeasurementRepositoryFake` runs the real per-pose capture-qc.md
/// tables over each scenario's metrics.
class CameraServiceFake implements CameraService {
  CameraServiceFake({
    this.frontSampleId = 'pass_frontal',
    this.sideSampleId = 'pass_side',
    this.permissionDenied = false,
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  static const String _frontAsset = 'assets/seed/dev/sample_frontal.png';
  static const String _sideAsset = 'assets/seed/dev/sample_side.png';

  final AssetBundle _bundle;

  /// The selected QC scenario per pose (see [CaptureSampleCatalog]).
  String frontSampleId;
  String sideSampleId;

  /// Simulates a denied CAMERA permission — [initialize] throws, driving
  /// the permission-denied EmptyState path in tests.
  final bool permissionDenied;

  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    if (permissionDenied) throw const CameraPermissionDeniedException();
    _ready = true;
  }

  @override
  Widget buildPreview({CapturePose pose = CapturePose.front}) => Image.asset(
    pose == CapturePose.front ? _frontAsset : _sideAsset,
    bundle: _bundle,
    fit: BoxFit.cover,
  );

  @override
  Future<CapturePhoto> takePhoto({
    CapturePose pose = CapturePose.front,
  }) async {
    final front = pose == CapturePose.front;
    final data = await _bundle.load(front ? _frontAsset : _sideAsset);
    return CapturePhoto(
      bytes: data.buffer.asUint8List(),
      sampleId: front ? frontSampleId : sideSampleId,
    );
  }

  @override
  Future<void> release() async {
    _ready = false;
  }
}
