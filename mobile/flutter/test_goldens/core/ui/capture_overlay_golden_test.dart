import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/capture_overlay.dart';
import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// CaptureOverlay (Figma 63:701) — `guide`
/// searching/aligned/countdown/qc-hint × `pose` front/side (M-10; the
/// sparse matrix is by design — the silhouette/hint swap per pose, the
/// rest of the chrome is pose-agnostic), both themes. The searching
/// silhouette pulses (MI-12), so the suite pumps a fixed frame.
void main() {
  themedGoldenTest(
    'CaptureOverlay matrix',
    fileName: 'capture_overlay',
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        GoldenTestScenario(
          name: 'guide searching (silhouette pulse)',
          child: const SizedBox(
            width: 270,
            child: CaptureOverlay(
              guide: CaptureGuide.searching,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'guide aligned (success stroke)',
          child: const SizedBox(
            width: 270,
            child: CaptureOverlay(
              guide: CaptureGuide.aligned,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'guide countdown (tick 2)',
          child: const SizedBox(
            width: 270,
            child: CaptureOverlay(
              guide: CaptureGuide.countdown,
              countdown: CountdownCount.two,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'guide qc-hint (too_far, first-failure-only)',
          child: const SizedBox(
            width: 270,
            child: CaptureOverlay(
              guide: CaptureGuide.qcHint,
              qcCode: QcFailCode.tooFar,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'pose side, searching (539:2 — right-profile silhouette)',
          child: const SizedBox(
            width: 270,
            child: CaptureOverlay(
              guide: CaptureGuide.searching,
              pose: CapturePose.side,
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'pose side, qc-hint (arms_position — relaxed-arms copy)',
          child: const SizedBox(
            width: 270,
            child: CaptureOverlay(
              guide: CaptureGuide.qcHint,
              pose: CapturePose.side,
              qcCode: QcFailCode.armsPosition,
            ),
          ),
        ),
      ],
    ),
  );
}
