import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/presentation/capture_screen.dart';
import 'package:apparule/src/features/measurements/presentation/capture_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// Pins the C6 screen to one state — build() returns the fixture, so the
/// golden renders a deterministic step without driving the flow.
class _FixedCaptureViewModel extends CaptureViewModel {
  _FixedCaptureViewModel(this.fixed);

  final CaptureState fixed;

  @override
  CaptureState build() => fixed;
}

Override _fixedState(CaptureState state) =>
    captureViewModelProvider.overrideWith(() => _FixedCaptureViewModel(state));

final MeasurementSession _resultsFixture = MeasurementSession(
  id: 'sess-golden',
  method: 'mediapipe_2d_v2',
  status: SessionStatus.pendingSave,
  inputHeightCm: 168,
  createdAt: DateTime.utc(2026, 7, 22),
  measurements: const <Measurement>[
    Measurement(
      id: 'm-golden-1',
      name: 'shoulder_width',
      valueCm: 42.6,
      confidence: 0.92,
    ),
    Measurement(
      id: 'm-golden-2',
      name: 'hip_width',
      valueCm: 35.5,
      confidence: 0.62,
    ),
  ],
);

/// C6 capture — the screen-level compositions per step (§10), both
/// themes. The viewfinder/processing steps host repeating MI-12 motion,
/// so every scenario pumps the deterministic bounded frame.
void main() {
  themedGoldenTest(
    'CaptureScreen height step',
    fileName: 'capture_screen_height',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'height input (canvas 530:4 — after the two poses)',
          child: screenFrame(
            const CaptureScreen(),
            overrides: <Override>[
              _fixedState(
                const CaptureState(step: CaptureStep.height, heightCm: 170),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'CaptureScreen viewfinder',
    fileName: 'capture_screen_camera',
    pumpBeforeTest: precacheThenFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'searching, Pose 1 of 2 (173:574)',
          child: screenFrame(
            const CaptureScreen(),
            overrides: <Override>[
              _fixedState(
                const CaptureState(heightCm: 168, cameraReady: true),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'CaptureScreen viewfinder side',
    fileName: 'capture_screen_camera_side',
    pumpBeforeTest: precacheThenFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name:
              'searching, Pose 2 of 2 — right-profile silhouette, '
              'neutral dark feed (540:9224)',
          child: screenFrame(
            const CaptureScreen(),
            overrides: <Override>[
              _fixedState(
                const CaptureState(
                  pose: CapturePose.side,
                  heightCm: 168,
                  cameraReady: true,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'CaptureScreen countdown',
    fileName: 'capture_screen_countdown',
    pumpBeforeTest: precacheThenFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'tick 2 of 3-2-1',
          child: screenFrame(
            const CaptureScreen(),
            overrides: <Override>[
              _fixedState(
                const CaptureState(
                  heightCm: 168,
                  cameraReady: true,
                  countdown: CountdownCount.two,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'CaptureScreen processing',
    fileName: 'capture_screen_processing',
    pumpBeforeTest: precacheThenFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'constellation over the capture',
          child: screenFrame(
            const CaptureScreen(),
            overrides: <Override>[
              _fixedState(
                const CaptureState(
                  step: CaptureStep.processing,
                  heightCm: 168,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'CaptureScreen QC fail',
    fileName: 'capture_screen_qc_fail',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'first-failure hint (not_frontal, pose 1)',
          child: screenFrame(
            const CaptureScreen(),
            overrides: <Override>[
              _fixedState(
                const CaptureState(
                  step: CaptureStep.qcFail,
                  heightCm: 168,
                  qcFailCode: 'not_frontal',
                  qcFailPose: CapturePose.front,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'CaptureScreen QC fail side',
    fileName: 'capture_screen_qc_fail_side',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'pose-contextual arms hint (arms_position, pose 2)',
          child: screenFrame(
            const CaptureScreen(),
            overrides: <Override>[
              _fixedState(
                const CaptureState(
                  step: CaptureStep.qcFail,
                  heightCm: 168,
                  qcFailCode: 'arms_position',
                  qcFailPose: CapturePose.side,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'CaptureScreen results',
    fileName: 'capture_screen_results',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'stagger list + confidence pill',
          child: screenFrame(
            const CaptureScreen(),
            overrides: <Override>[
              _fixedState(
                CaptureState(
                  step: CaptureStep.results,
                  heightCm: 168,
                  session: _resultsFixture,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
