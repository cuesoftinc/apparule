import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_picker_service.g.dart';

/// One picked image candidate — what the C15 composer validates against
/// the ratified media contract (≤10 items, JPEG/PNG/WebP, ≤10 MB;
/// pages.md B5, decided — mirrored to C15). [url] is the media source the
/// tile previews and the published `PostMedia.url` carries: the fake
/// serves the bundled §6 seed pool (`/demo/…`), the live picker an
/// absolute device file path — `seedMediaImage` resolves both.
class PickedMedia {
  const PickedMedia({
    required this.url,
    required this.sizeBytes,
    required this.mimeType,
  });

  final String url;
  final int sizeBytes;

  /// IANA type (`image/jpeg` …) — the composer's type gate compares
  /// against the ratified allow-list verbatim.
  final String mimeType;
}

/// Stateless-contract device-picker seam (the `CameraService` precedent,
/// mobile-implementation.md §3 services): the C15 composer adds photos
/// through this interface only. `MediaPickerServiceLive` wraps the
/// `image_picker` plugin (the platform photo picker);
/// `MediaPickerServiceFake` serves bundled §6 sample images so
/// simulators, CI and the dev flavor complete the full publish journey
/// without a photo library.
abstract class MediaPickerService {
  /// Opens the multi-image picker; resolves to the picked candidates
  /// (empty when the user cancels). [limit] is the composer's remaining
  /// room (10 − already picked) — pickers may still return more (the
  /// platform sheet can't always cap), so the composer re-gates count.
  Future<List<PickedMedia>> pickImages({required int limit});
}

/// Overridden per entrypoint (di.dart): fakes carry
/// `MediaPickerServiceFake`; prod swaps in `MediaPickerServiceLive`
/// (hardware/photo-library access is not env-gated the way `*Remote`
/// repositories are — the real picker ships now).
@Riverpod(keepAlive: true)
MediaPickerService mediaPickerService(Ref ref) => throw UnimplementedError(
  'mediaPickerService must be overridden with a live or fake '
  'implementation (mobile-implementation.md §3 service seams)',
);
