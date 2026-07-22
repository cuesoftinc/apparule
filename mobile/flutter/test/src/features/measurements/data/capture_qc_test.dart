import 'package:apparule/src/features/measurements/data/capture_qc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The capture-qc.md contract, rule by rule: every §1/§2 fail code fires
/// from its documented threshold, multiple faults report the first by
/// table order, and the §3/§4 formulas produce the spec'd numbers.
void main() {
  group('firstQcFailure — §1 image pre-checks', () {
    test('passing defaults pass', () {
      expect(firstQcFailure(const CaptureFrameMetrics()), isNull);
    });

    test('undecodable image', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(decodable: false)),
        'undecodable_image',
      );
    });

    test('low resolution — short edge under 480px', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(shortEdgePx: 479)),
        'low_resolution',
      );
      expect(
        firstQcFailure(const CaptureFrameMetrics(shortEdgePx: 480)),
        isNull,
      );
    });

    test('poor lighting — mean luma outside [40, 215], both ends', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(meanLuma: 39)),
        'poor_lighting',
      );
      expect(
        firstQcFailure(const CaptureFrameMetrics(meanLuma: 216)),
        'poor_lighting',
      );
      expect(firstQcFailure(const CaptureFrameMetrics(meanLuma: 40)), isNull);
      expect(firstQcFailure(const CaptureFrameMetrics(meanLuma: 215)), isNull);
    });

    test('blurry — Laplacian variance under 60', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(laplacianVariance: 59)),
        'blurry',
      );
      expect(
        firstQcFailure(const CaptureFrameMetrics(laplacianVariance: 60)),
        isNull,
      );
    });
  });

  group('firstQcFailure — §2 pose QC', () {
    test('no body', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(posesDetected: 0)),
        'no_body',
      );
    });

    test('multiple bodies', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(posesDetected: 2)),
        'multiple_bodies',
      );
    });

    test('partial body — key-set visibility under 0.5', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(minKeyVisibility: 0.49)),
        'partial_body',
      );
    });

    test('partial body — landmark margin under 2%', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(minLandmarkMarginPct: 1.5)),
        'partial_body',
      );
    });

    test('not frontal — shoulder/hip ratio outside [0.9, 2.2]', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(shoulderHipRatio: 0.89)),
        'not_frontal',
      );
      expect(
        firstQcFailure(const CaptureFrameMetrics(shoulderHipRatio: 2.21)),
        'not_frontal',
      );
    });

    test('not frontal — shoulder z-delta over 0.15', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(shoulderZDelta: 0.16)),
        'not_frontal',
      );
    });

    test('camera tilt — over 15° off vertical, either direction', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(tiltDegrees: 15.1)),
        'camera_tilt',
      );
      expect(
        firstQcFailure(const CaptureFrameMetrics(tiltDegrees: -15.1)),
        'camera_tilt',
      );
      expect(
        firstQcFailure(const CaptureFrameMetrics(tiltDegrees: 15)),
        isNull,
      );
    });

    test('arms position — wrist/hip clearance under 5%', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(wristHipClearancePct: 4.9)),
        'arms_position',
      );
    });

    test('too far — body under 40% of frame height', () {
      expect(
        firstQcFailure(const CaptureFrameMetrics(bodyHeightFraction: 0.39)),
        'too_far',
      );
    });
  });

  group('first-failure-only ordering (the doc reporting rule)', () {
    test('a multi-fault frame reports the FIRST failing row, never a list', () {
      // Dark AND blurry AND too far: brightness sits above blur and
      // scale-sanity in the table.
      const multiFault = CaptureFrameMetrics(
        meanLuma: 24,
        laplacianVariance: 32,
        bodyHeightFraction: 0.28,
      );
      expect(firstQcFailure(multiFault), 'poor_lighting');
    });

    test('§1 pre-checks precede §2 pose rows', () {
      const undecodableAndBodyless = CaptureFrameMetrics(
        decodable: false,
        posesDetected: 0,
      );
      expect(firstQcFailure(undecodableAndBodyless), 'undecodable_image');
    });
  });

  group('scaleFactor — §3 height correction', () {
    test('applies the 0.93 stature correction (mediapipe_2d_v2)', () {
      // 168 cm over 1100 px: (168 × 0.93) / 1100.
      expect(scaleFactor(168, 1100), closeTo(0.142036, 1e-6));
    });
  });

  group('measurementConfidence — §4 formula', () {
    test('frontal + sharp: confidence = mean visibility', () {
      expect(
        measurementConfidence(
          meanVisibility: 0.92,
          shoulderHipRatio: 1.2,
          laplacianVariance: 180,
        ),
        closeTo(0.92, 1e-9),
      );
    });

    test('off-frontal ratio applies the 0.85 factor', () {
      expect(
        measurementConfidence(
          meanVisibility: 0.92,
          shoulderHipRatio: 1, // outside [1.2, 1.9]
          laplacianVariance: 180,
        ),
        closeTo(0.92 * 0.85, 1e-9),
      );
    });

    test('soft sharpness (60 ≤ var < 120) applies the 0.9 factor', () {
      expect(
        measurementConfidence(
          meanVisibility: 0.92,
          shoulderHipRatio: 1.2,
          laplacianVariance: 100,
        ),
        closeTo(0.92 * 0.9, 1e-9),
      );
    });

    test('clamps into [0, 1]', () {
      expect(
        measurementConfidence(
          meanVisibility: 1.2,
          shoulderHipRatio: 1.2,
          laplacianVariance: 180,
        ),
        1.0,
      );
    });
  });
}
