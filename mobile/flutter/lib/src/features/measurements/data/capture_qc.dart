/// The capture-qc.md contract, executable: the §1 image pre-checks and §2
/// **per-pose** QC tables in their exact order (M-10: the front pose
/// keeps the frontality table; the side pose swaps in the
/// profile-orientation and arms-relaxed rows), the §3 height-scale
/// correction, and the §4 per-measurement confidence formula. This is
/// what makes the fake HONEST — `MeasurementRepositoryFake` runs these
/// rules over a sample frame's simulated pipeline metrics instead of
/// hardcoding verdicts, so first-failure ordering, thresholds, and
/// confidence values all behave exactly as the served pipeline will
/// (`app/config.py :: QCThresholds` is the server twin of
/// [QcThresholds]).
library;

import 'package:apparule/src/core/utils/capture_pose.dart';

/// The §5 config block, client-side: every §1/§2 threshold as a tuneable
/// constant in ONE place — never scattered magic numbers.
class QcThresholds {
  const QcThresholds({
    this.minShortEdgePx = 480,
    this.minMeanLuma = 40,
    this.maxMeanLuma = 215,
    this.minLaplacianVariance = 60,
    this.minKeyVisibility = 0.5,
    this.minLandmarkMarginPct = 2,
    this.minShoulderHipRatio = 0.9,
    this.maxShoulderHipRatio = 2.2,
    this.maxShoulderZDelta = 0.15,
    this.maxTiltDegrees = 15,
    this.minWristHipClearancePct = 5,
    this.minBodyHeightFraction = 0.4,
    this.statureCorrection = 0.93,
    this.confidenceFrontalMin = 1.2,
    this.confidenceFrontalMax = 1.9,
    this.offFrontalFactor = 0.85,
    this.sharpLaplacianVariance = 120,
    this.softSharpnessFactor = 0.9,
    this.version = 'qc-2026-07-22',
  });

  /// §1 Resolution: short edge ≥ 480px.
  final double minShortEdgePx;

  /// §1 Brightness: mean luma within [40, 215].
  final double minMeanLuma;
  final double maxMeanLuma;

  /// §1 Blur: Laplacian variance ≥ 60.
  final double minLaplacianVariance;

  /// §2 Full body: min visibility over HEAD∪SHOULDERS∪HIPS∪ANKLES ≥ 0.5.
  final double minKeyVisibility;

  /// §2 In-frame margins: all key landmarks within [2%, 98%] of both axes.
  final double minLandmarkMarginPct;

  /// §2 Frontality: shoulder-width ÷ hip-width within [0.9, 2.2]…
  final double minShoulderHipRatio;
  final double maxShoulderHipRatio;

  /// …AND both shoulders' z within 0.15 of each other.
  final double maxShoulderZDelta;

  /// §2 Upright: nose→ankle-midpoint axis within 15° of vertical.
  final double maxTiltDegrees;

  /// §2 Arms clearance: wrists ≥ 5% image-width from the hips.
  final double minWristHipClearancePct;

  /// §2 Scale sanity: body_height_px ≥ 40% of image height.
  final double minBodyHeightFraction;

  /// §3: nose→ankle-midpoint distance is ~93% of true stature — the
  /// correction that makes the method `mediapipe_2d_v2`.
  final double statureCorrection;

  /// §4 frontality factor: 1.0 when shoulder/hip ratio ∈ [1.2, 1.9],
  /// else 0.85.
  final double confidenceFrontalMin;
  final double confidenceFrontalMax;
  final double offFrontalFactor;

  /// §4 sharpness factor: 1.0 when Laplacian var ≥ 120, 0.9 when ≥ 60.
  final double sharpLaplacianVariance;
  final double softSharpnessFactor;

  /// §5: echoed per session so historical sessions stay interpretable
  /// after tuning.
  final String version;
}

/// What the pipeline measures about one frame before/after pose
/// detection — the fake's stand-in for cv2 + MediaPipe analysis
/// (`capture_samples.json` overrides these passing defaults per sample).
class CaptureFrameMetrics {
  const CaptureFrameMetrics({
    this.decodable = true,
    this.shortEdgePx = 720,
    this.meanLuma = 128,
    this.laplacianVariance = 180,
    this.posesDetected = 1,
    this.minKeyVisibility = 0.62,
    this.minLandmarkMarginPct = 6,
    this.shoulderHipRatio = 1.2,
    this.shoulderZDelta = 0.04,
    this.tiltDegrees = 2,
    this.wristHipClearancePct = 8,
    this.bodyHeightFraction = 0.86,
    this.bodyHeightPx = 1100,
    this.shoulderWidthPx = 300,
    this.hipWidthPx = 250,
    this.landmarkVisibility = const <String, double>{
      'shoulder_width': 0.92,
      'hip_width': 0.62,
    },
  });

  /// The SIDE pose's passing defaults: the orientation and arms rows
  /// invert on the side table (capture-qc.md §2 deltas), so a frame that
  /// passes the front table is exactly what `not_side_profile` rejects —
  /// unknown/live side frames must evaluate against a side-on subject
  /// (stacked shoulders in depth, foreshortened width, arms hanging).
  const CaptureFrameMetrics.passingSide()
    : this(
        shoulderHipRatio: 0.72,
        shoulderZDelta: 0.28,
        wristHipClearancePct: 2,
      );

  /// Parses a `capture_samples.json` metrics override block — absent
  /// fields keep the passing-frame defaults.
  factory CaptureFrameMetrics.fromJson(Map<String, dynamic> json) {
    const defaults = CaptureFrameMetrics();
    double read(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    return CaptureFrameMetrics(
      decodable: json['decodable'] as bool? ?? defaults.decodable,
      shortEdgePx: read('short_edge_px', defaults.shortEdgePx),
      meanLuma: read('mean_luma', defaults.meanLuma),
      laplacianVariance: read(
        'laplacian_variance',
        defaults.laplacianVariance,
      ),
      posesDetected:
          (json['poses_detected'] as num?)?.toInt() ?? defaults.posesDetected,
      minKeyVisibility: read('min_key_visibility', defaults.minKeyVisibility),
      minLandmarkMarginPct: read(
        'min_landmark_margin_pct',
        defaults.minLandmarkMarginPct,
      ),
      shoulderHipRatio: read('shoulder_hip_ratio', defaults.shoulderHipRatio),
      shoulderZDelta: read('shoulder_z_delta', defaults.shoulderZDelta),
      tiltDegrees: read('tilt_degrees', defaults.tiltDegrees),
      wristHipClearancePct: read(
        'wrist_hip_clearance_pct',
        defaults.wristHipClearancePct,
      ),
      bodyHeightFraction: read(
        'body_height_fraction',
        defaults.bodyHeightFraction,
      ),
      bodyHeightPx: read('body_height_px', defaults.bodyHeightPx),
      shoulderWidthPx: read('shoulder_width_px', defaults.shoulderWidthPx),
      hipWidthPx: read('hip_width_px', defaults.hipWidthPx),
      landmarkVisibility:
          (json['landmark_visibility'] as Map<String, dynamic>?)?.map(
            (name, vis) => MapEntry(name, (vis as num).toDouble()),
          ) ??
          defaults.landmarkVisibility,
    );
  }

  final bool decodable;
  final double shortEdgePx;
  final double meanLuma;
  final double laplacianVariance;
  final int posesDetected;
  final double minKeyVisibility;
  final double minLandmarkMarginPct;
  final double shoulderHipRatio;
  final double shoulderZDelta;
  final double tiltDegrees;
  final double wristHipClearancePct;
  final double bodyHeightFraction;
  final double bodyHeightPx;
  final double shoulderWidthPx;
  final double hipWidthPx;

  /// Mean landmark visibility per measurement name (§4 `mean_vis(m)`).
  final Map<String, double> landmarkVisibility;
}

/// Runs the §1 pre-checks then the §2 table **for [pose]** IN ORDER and
/// returns the first failing wire code, or `null` on pass. Multiple
/// failures report the first by table order — one actionable instruction
/// beats a list (the doc's own reporting rule; surfaced
/// first-failure-only **per pose** in C6). The side pose (M-10) runs the
/// same pre-checks and body rows, swapping exactly two rows in place:
/// frontality → profile orientation (`not_side_profile`), arms clearance
/// → arms relaxed (`arms_position`, side copy).
String? firstQcFailure(
  CaptureFrameMetrics m, {
  CapturePose pose = CapturePose.front,
  QcThresholds thresholds = const QcThresholds(),
}) {
  final t = thresholds;
  // §1 image pre-checks (before pose detection) — per image, both poses.
  if (!m.decodable) return 'undecodable_image';
  if (m.shortEdgePx < t.minShortEdgePx) return 'low_resolution';
  if (m.meanLuma < t.minMeanLuma || m.meanLuma > t.maxMeanLuma) {
    return 'poor_lighting';
  }
  if (m.laplacianVariance < t.minLaplacianVariance) return 'blurry';
  // §2 pose QC (after detection) — the shared body rows.
  if (m.posesDetected < 1) return 'no_body';
  if (m.posesDetected > 1) return 'multiple_bodies';
  if (m.minKeyVisibility < t.minKeyVisibility) return 'partial_body';
  if (m.minLandmarkMarginPct < t.minLandmarkMarginPct) return 'partial_body';
  // Orientation row — frontality (front) / profile orientation (side,
  // the frontality rule inverted: near/far shoulder depth separation AND
  // foreshortened shoulders).
  switch (pose) {
    case CapturePose.front:
      if (m.shoulderHipRatio < t.minShoulderHipRatio ||
          m.shoulderHipRatio > t.maxShoulderHipRatio ||
          m.shoulderZDelta > t.maxShoulderZDelta) {
        return 'not_frontal';
      }
    case CapturePose.side:
      if (m.shoulderZDelta < t.maxShoulderZDelta ||
          m.shoulderHipRatio >= t.minShoulderHipRatio) {
        return 'not_side_profile';
      }
  }
  if (m.tiltDegrees.abs() > t.maxTiltDegrees) return 'camera_tilt';
  // Arms row — clearance (front: wrists ≥ 5% away) / relaxed (side:
  // wrists within 5%, hanging at the sides); same position in the table.
  switch (pose) {
    case CapturePose.front:
      if (m.wristHipClearancePct < t.minWristHipClearancePct) {
        return 'arms_position';
      }
    case CapturePose.side:
      if (m.wristHipClearancePct > t.minWristHipClearancePct) {
        return 'arms_position';
      }
  }
  if (m.bodyHeightFraction < t.minBodyHeightFraction) return 'too_far';
  return null;
}

/// §3: `scale = (user_height_cm × 0.93) / body_height_px` — the corrected
/// scale that ships as `method: mediapipe_2d_v2`.
double scaleFactor(
  double userHeightCm,
  double bodyHeightPx, {
  QcThresholds thresholds = const QcThresholds(),
}) => (userHeightCm * thresholds.statureCorrection) / bodyHeightPx;

/// §4: `confidence(m) = clamp01(mean_vis(m) × frontality_factor ×
/// sharpness_factor)`.
double measurementConfidence({
  required double meanVisibility,
  required double shoulderHipRatio,
  required double laplacianVariance,
  QcThresholds thresholds = const QcThresholds(),
}) {
  final t = thresholds;
  final frontality =
      (shoulderHipRatio >= t.confidenceFrontalMin &&
          shoulderHipRatio <= t.confidenceFrontalMax)
      ? 1.0
      : t.offFrontalFactor;
  // 1.0 when sharp (≥120); 0.9 down to the blur floor (≥60). Below 60
  // the frame already failed `blurry`, so the soft factor is the floor.
  final sharpness = laplacianVariance >= t.sharpLaplacianVariance
      ? 1.0
      : t.softSharpnessFactor;
  final value = meanVisibility * frontality * sharpness;
  return value.clamp(0.0, 1.0);
}
