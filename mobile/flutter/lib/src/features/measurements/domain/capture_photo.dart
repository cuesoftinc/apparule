import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'capture_photo.freezed.dart';

/// A captured frame on its way into `POST /measure` (api.md §1) — the
/// multipart `image` part once the API wave lands.
@freezed
abstract class CapturePhoto with _$CapturePhoto {
  const factory CapturePhoto({
    required Uint8List bytes,

    /// Dev seam: the fake camera stamps which sample-frame scenario this
    /// is (`capture_samples.json`), and `MeasurementRepositoryFake` runs
    /// the QC table over that scenario's simulated metrics. Live-camera
    /// photos carry `null` and evaluate as the passing defaults.
    String? sampleId,
  }) = _CapturePhoto;
}
