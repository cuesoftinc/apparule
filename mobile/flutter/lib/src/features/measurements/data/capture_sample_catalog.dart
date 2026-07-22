import 'dart:convert';

import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:apparule/src/features/measurements/data/capture_qc.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_sample_catalog.g.dart';

/// One fake-camera scenario (`capture_samples.json`): the bundled frame
/// plus the simulated pipeline metrics the QC table evaluates. [pose]
/// names which pose's table the scenario targets (M-10 per-pose QC) —
/// the dev selector lists front scenarios for Pose 1 and side scenarios
/// for Pose 2.
class CaptureSample {
  const CaptureSample({
    required this.id,
    required this.label,
    required this.pose,
    required this.metrics,
  });

  final String id;

  /// Human label for the dev-flavor QC selector.
  final String label;

  /// Which pose's QC table this scenario exercises.
  final CapturePose pose;

  final CaptureFrameMetrics metrics;
}

/// The dev seam's sample-frame catalog: a seeded happy path plus every
/// capture-qc.md fail code **per pose**, each reproducible by rule (the
/// fake runs the real per-pose threshold tables over
/// [CaptureSample.metrics], mobile-implementation.md §10). Loaded from
/// `assets/seed/dev/`, so it ships in dev bundles only.
class CaptureSampleCatalog {
  const CaptureSampleCatalog({required this.imageAsset, required this.samples});

  /// The §6 seed asset every scenario renders/captures.
  static const String seedAsset = 'assets/seed/dev/capture_samples.json';

  static Future<CaptureSampleCatalog> load({AssetBundle? bundle}) async {
    // Instance-scoped bundle (see MeasurementRepositoryFake): the global
    // rootBundle string cache deadlocks across widget-test zones.
    final raw = await (bundle ?? PlatformAssetBundle()).loadString(seedAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return CaptureSampleCatalog(
      imageAsset: json['image'] as String,
      samples: <CaptureSample>[
        for (final entry in json['samples'] as List<dynamic>)
          CaptureSample(
            id: (entry as Map<String, dynamic>)['id'] as String,
            label: entry['label'] as String,
            pose: CapturePose.fromWireName(
              entry['pose'] as String? ?? 'front',
            ),
            metrics: CaptureFrameMetrics.fromJson(
              entry['metrics'] as Map<String, dynamic>,
            ),
          ),
      ],
    );
  }

  /// The bundled sample frontal frame (all front scenarios share it —
  /// what varies is the simulated analysis; side scenarios capture the
  /// neutral dark side frame).
  final String imageAsset;

  final List<CaptureSample> samples;

  /// The dev selector's per-pose scenario group.
  List<CaptureSample> samplesFor(CapturePose pose) => <CaptureSample>[
    for (final sample in samples)
      if (sample.pose == pose) sample,
  ];

  /// Metrics for a captured photo's `sampleId`; unknown/`null` ids (live
  /// camera) evaluate as [pose]'s passing defaults — the side table
  /// inverts the orientation/arms rows, so its defaults must describe a
  /// side-on subject (capture-qc.md §2 deltas).
  CaptureFrameMetrics metricsFor(
    String? sampleId, {
    CapturePose pose = CapturePose.front,
  }) {
    for (final sample in samples) {
      if (sample.id == sampleId) return sample.metrics;
    }
    return pose == CapturePose.front
        ? const CaptureFrameMetrics()
        : const CaptureFrameMetrics.passingSide();
  }
}

/// Catalog for the capture screen's dev-flavor QC selector (the fake
/// repository loads its own copy lazily).
@Riverpod(keepAlive: true)
Future<CaptureSampleCatalog> captureSampleCatalog(Ref ref) =>
    CaptureSampleCatalog.load();
