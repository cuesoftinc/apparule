import 'dart:collection';

import 'package:apparule/src/features/feed/data/media_picker_service.dart';

/// Bundled-sample picker (mobile-implementation.md §6 TEST_MODE seam —
/// the `CameraServiceFake` sibling): each invocation "picks" the next
/// [batchSize] frames from the §6 CC-licensed demo pool
/// (`assets/seed/dev/demo/`, the same photography the seed posts
/// render), so simulators, CI and the dev flavor exercise the full C15
/// add-photos → publish journey without a photo library. Every sample
/// reports an in-contract JPEG well under the 10 MB gate.
///
/// Tests script rejections by [enqueue]ing a result — a queued batch is
/// served verbatim (oversize, wrong-type, over-count) before the pool
/// rotation resumes.
class MediaPickerServiceFake implements MediaPickerService {
  MediaPickerServiceFake({this.batchSize = 3});

  /// Samples served per invocation (the canvas ready-frame's 3 tiles).
  final int batchSize;

  /// The §6 demo pool, rotated round-robin across invocations.
  static const List<String> samplePool = <String>[
    '/demo/outfit-w16.jpg',
    '/demo/outfit-w17.jpg',
    '/demo/outfit-w18.jpg',
    '/demo/outfit-w19.jpg',
    '/demo/outfit-w00.jpg',
    '/demo/outfit-w01.jpg',
  ];

  final Queue<List<PickedMedia>> _scripted = Queue<List<PickedMedia>>();
  int _cursor = 0;

  /// Scripts the NEXT [pickImages] result (test seam) — served once,
  /// verbatim, bypassing the pool rotation and the `limit` alike (a
  /// platform sheet can't always cap the selection; the composer
  /// re-gates).
  void enqueue(List<PickedMedia> result) => _scripted.add(result);

  @override
  Future<List<PickedMedia>> pickImages({required int limit}) async {
    if (_scripted.isNotEmpty) return _scripted.removeFirst();
    final count = limit < batchSize ? limit : batchSize;
    final picked = <PickedMedia>[
      for (var i = 0; i < count; i++)
        PickedMedia(
          url: samplePool[(_cursor + i) % samplePool.length],
          sizeBytes: 512 * 1024,
          mimeType: 'image/jpeg',
        ),
    ];
    _cursor = (_cursor + picked.length) % samplePool.length;
    return picked;
  }
}
