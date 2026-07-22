import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/capture_sample_catalog.dart';
import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The §10 TEST_MODE camera: previews and captures the bundled sample
/// frontal frame, so simulators, CI, and the dev flavor run the full C6
/// journey without hardware. [sampleId] selects which QC scenario the
/// captured photo carries (`capture_samples.json`) — the capture screen's
/// dev-flavor selector swaps it, and `MeasurementRepositoryFake` runs the
/// real capture-qc.md table over that scenario's metrics.
class CameraServiceFake implements CameraService {
  CameraServiceFake({
    this.sampleId = 'pass_frontal',
    this.permissionDenied = false,
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  static const String _imageAsset = 'assets/seed/dev/sample_frontal.png';

  final AssetBundle _bundle;

  /// The selected QC scenario (see [CaptureSampleCatalog]).
  String sampleId;

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
  Widget buildPreview() =>
      Image.asset(_imageAsset, bundle: _bundle, fit: BoxFit.cover);

  @override
  Future<CapturePhoto> takePhoto() async {
    final data = await _bundle.load(_imageAsset);
    return CapturePhoto(bytes: data.buffer.asUint8List(), sampleId: sampleId);
  }

  @override
  Future<void> release() async {
    _ready = false;
  }
}
