import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/guide_page.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

const String _introBullet =
    'How to take your body measurement accurately — two photos (front and '
    'side) plus your height is all it takes.';
const String _readyBullet1 =
    'Wear fitted clothes — loose fabric hides your shape. Tie long hair '
    'back.';
const String _setupBullet1 =
    'Stand your phone upright on a flat surface, camera facing you, and '
    'step 5–6 feet back.';
const String _setupBullet3 =
    'Face the light — even, bright lighting keeps the photo sharp.';
const String _poseFrontBullet2 =
    'Raise both arms to about 45 degrees and keep your feet about a foot '
    'apart.';

/// GuidePage (Figma 526:33) — the `step` axis: intro / ready / setup /
/// pose-front / pose-side, both themes (the canvas-first replacement for
/// the 2023 navy photo art; dark-mode token-true by construction — every
/// stroke binds text-2/accent/border).
void main() {
  themedGoldenTest(
    'GuidePage matrix',
    fileName: 'guide_page',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: <Widget>[
        GoldenTestScenario(
          name: 'step intro (529:2441 — measure lines + height arrow)',
          child: const SizedBox(
            width: 390,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GuidePage(
                step: GuideStep.intro,
                title: 'Guide A-Z',
                bullets: <String>[_introBullet],
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'step ready (529:2477 — callout chips)',
          child: const SizedBox(
            width: 390,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GuidePage(
                step: GuideStep.ready,
                title: 'Get ready',
                bullets: <String>[
                  _readyBullet1,
                  'Bare feet on the floor — socks are fine.',
                ],
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'step setup (529:8935 — phone, sightline, light)',
          child: const SizedBox(
            width: 390,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GuidePage(
                step: GuideStep.setup,
                title: 'Set your phone up',
                bullets: <String>[
                  _setupBullet1,
                  'Make sure no one else is in the frame.',
                  _setupBullet3,
                ],
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'step pose-front (529:8975 — 45° arm rays)',
          child: const SizedBox(
            width: 390,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GuidePage(
                step: GuideStep.poseFront,
                title: 'Strike the pose',
                bullets: <String>[
                  'Stand tall facing the camera, head high.',
                  _poseFrontBullet2,
                ],
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'step pose-side (540:9172 — turn arrow, relaxed arms)',
          child: const SizedBox(
            width: 390,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GuidePage(
                step: GuideStep.poseSide,
                title: 'Turn to the side',
                bullets: <String>[
                  'Turn right 90 degrees — your side to the camera.',
                  'Stand straight with your arms relaxed at your sides.',
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
