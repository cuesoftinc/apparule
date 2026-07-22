import 'dart:convert';

import 'package:apparule/src/features/measurements/data/capture_qc.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_sample_catalog.g.dart';

/// One fake-camera scenario (`capture_samples.json`): the bundled frame
/// plus the simulated pipeline metrics the QC table evaluates.
class CaptureSample {
  const CaptureSample({
    required this.id,
    required this.label,
    required this.metrics,
  });

  final String id;

  /// Human label for the dev-flavor QC selector.
  final String label;

  final CaptureFrameMetrics metrics;
}

/// The dev seam's sample-frame catalog: a seeded happy path plus every
/// capture-qc.md fail code, each reproducible by rule (the fake runs the
/// real threshold table over [CaptureSample.metrics], mobile-
/// implementation.md §10). Loaded from `assets/seed/dev/`, so it ships in
/// dev bundles only.
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
            metrics: CaptureFrameMetrics.fromJson(
              entry['metrics'] as Map<String, dynamic>,
            ),
          ),
      ],
    );
  }

  /// The bundled sample frontal frame (all scenarios share it — what
  /// varies is the simulated analysis).
  final String imageAsset;

  final List<CaptureSample> samples;

  /// Metrics for a captured photo's `sampleId`; unknown/`null` ids (live
  /// camera) evaluate as the passing defaults.
  CaptureFrameMetrics metricsFor(String? sampleId) {
    for (final sample in samples) {
      if (sample.id == sampleId) return sample.metrics;
    }
    return const CaptureFrameMetrics();
  }
}

/// Catalog for the capture screen's dev-flavor QC selector (the fake
/// repository loads its own copy lazily).
@Riverpod(keepAlive: true)
Future<CaptureSampleCatalog> captureSampleCatalog(Ref ref) =>
    CaptureSampleCatalog.load();
