import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/capture_overlay.dart';
import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// CaptureOverlay (Figma 63:701) — `guide`
/// searching/aligned/countdown/qc-hint, both themes. The searching
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
      ],
    ),
  );
}
