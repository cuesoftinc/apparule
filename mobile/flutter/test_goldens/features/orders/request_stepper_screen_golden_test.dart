import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/presentation/request_stepper_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C5 step 1 — the measurement-snapshot picker over the seeded vault
/// (freshness ladder pills + frozen-copy footer), both themes.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'RequestStepperScreen step 1',
    fileName: 'request_stepper_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'snapshot picker',
          child: screenFrame(
            const RequestStepperScreen(postId: 'post-ankara-gown'),
            postRepository: PostRepositoryFake(now: () => pinned),
            orderRepository: OrderRepositoryFake(now: () => pinned),
            measurementRepository: MeasurementRepositoryFake(
              now: () => pinned,
            ),
            overrides: <Override>[
              clockProvider.overrideWith(
                (ref) =>
                    () => pinned,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
