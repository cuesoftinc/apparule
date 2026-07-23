import 'package:apparule/src/features/feed/data/media_picker_service.dart';
import 'package:image_picker/image_picker.dart';

/// The platform photo picker (Android Photo Picker / iOS PHPicker via
/// the first-party `image_picker` plugin — pin flagged in pubspec.yaml).
/// Bound by the prod entrypoint only; dev/CI ride
/// `MediaPickerServiceFake` (the `CameraServiceLive` precedent).
class MediaPickerServiceLive implements MediaPickerService {
  MediaPickerServiceLive({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Extension fallback when the platform reports no MIME — the
  /// composer's type gate needs a value to compare against the ratified
  /// allow-list (unknown extensions surface as rejects, honestly).
  static const Map<String, String> _mimeByExtension = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  @override
  Future<List<PickedMedia>> pickImages({required int limit}) async {
    // `pickMultiImage` limits are best-effort per platform — the
    // composer re-gates count regardless (the seam's documented
    // contract). `limit` must be ≥2 for the plugin; a single remaining
    // slot falls back to the single-image picker.
    final files = limit >= 2
        ? await _picker.pickMultiImage(limit: limit)
        : <XFile>[?await _picker.pickImage(source: ImageSource.gallery)];
    return <PickedMedia>[
      for (final file in files)
        PickedMedia(
          url: file.path,
          sizeBytes: await file.length(),
          mimeType: file.mimeType ?? _mimeOf(file.path),
        ),
    ];
  }

  static String _mimeOf(String path) {
    final extension = path.split('.').last.toLowerCase();
    return _mimeByExtension[extension] ?? 'application/octet-stream';
  }
}
