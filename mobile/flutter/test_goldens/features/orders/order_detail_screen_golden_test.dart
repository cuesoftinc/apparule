import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C8 detail — timeline · escrow/dispute payment boxes · frozen snapshot
/// · thread, both themes. #APR-1042 is the escrow-held happy path;
/// #APR-1018 the dispute-frozen state (canvas C8-dispute narrative).
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  themedGoldenTest(
    'OrderDetailScreen seeded',
    fileName: 'order_detail_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'in_progress — escrow held (#APR-1042)',
          child: screenFrame(
            const OrderDetailScreen(orderId: 'req-apr-1042'),
            orderRepository: OrderRepositoryFake(now: () => pinned),
            overrides: <Override>[
              clockProvider.overrideWith(
                (ref) =>
                    () => pinned,
              ),
            ],
          ),
        ),
        GoldenTestScenario(
          name: 'disputed — payout frozen (#APR-1018)',
          child: screenFrame(
            const OrderDetailScreen(orderId: 'req-apr-1018'),
            orderRepository: OrderRepositoryFake(now: () => pinned),
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
