import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/orders/data/order_repository_fake.dart';
import 'package:apparule/src/features/orders/presentation/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/golden_themes.dart';
import '../../helpers/screen_frame.dart';

/// C8 detail — MI-14 timeline (terminal-error rung on the dispute) ·
/// escrow/dispute payment boxes (wired quiet CTAs) · frozen snapshot ·
/// dispute-reason section · thread, both themes. #APR-1042 is the
/// escrow-held happy path; #APR-1018 the dispute-frozen state (canvas
/// C8-dispute narrative).
///
/// Reduced motion: the MI-14 current-dot pulse REPEATS — under full
/// motion `settleThenPrecache` would never settle; the §5 fallback
/// renders the same anatomy statically (connectors fully drawn).
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Widget reducedMotion(Widget child) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    ),
  );

  themedGoldenTest(
    'OrderDetailScreen seeded',
    fileName: 'order_detail_screen',
    pumpBeforeTest: settleThenPrecache,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <GoldenTestScenario>[
        GoldenTestScenario(
          name: 'in_progress — escrow held (#APR-1042)',
          child: reducedMotion(
            screenFrame(
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
        ),
        GoldenTestScenario(
          name: 'disputed — payout frozen (#APR-1018)',
          child: reducedMotion(
            screenFrame(
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
        ),
      ],
    ),
  );
}
