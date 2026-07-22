import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/pump_app.dart';

/// C14 earnings & payouts: the canvas ledger states plus the honest
/// payout-request mutation.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Future<EarningsRepositoryFake> pump(
    WidgetTester tester, {
    String viewer = 'amara.designs',
    EarningsRepositoryFake? repository,
  }) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final fake =
        repository ??
        EarningsRepositoryFake(
          viewer: viewer,
          now: () => pinned,
          resolveDelay: Duration.zero,
        );
    await tester.pumpApp(
      const EarningsScreen(),
      earningsRepository: fake,
      overrides: <Override>[
        clockProvider.overrideWith(
          (ref) =>
              () => pinned,
        ),
      ],
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('renders the C14 canvas story: summary, status line, '
      'tabular ledger', (tester) async {
    await pump(tester);

    expect(find.text('Earnings & payouts'), findsWidgets);
    expect(find.text('₦82,500'), findsOneWidget);
    expect(find.text('₦45,000'), findsOneWidget);
    expect(
      find.text('GTBank ••• 4521 — AMARA OKAFOR'),
      findsOneWidget,
    );
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Change →'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    // Canvas rows: payouts negative, escrow positive, the fee line.
    expect(find.text('Payout to GTBank ••• 4521'), findsNWidgets(2));
    expect(find.text('−₦55,800'), findsOneWidget);
    expect(find.text('Escrow held · #APR-1042'), findsOneWidget);
    expect(find.text('+₦45,000'), findsOneWidget);
    expect(find.text('Platform fee (10%) · #APR-1058'), findsOneWidget);
    expect(find.text('PSK-9921404 · Jul 16'), findsOneWidget);
  });

  testWidgets('a payout request MOVES the balance into a processing '
      'row', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(LucideIcons.ellipsis));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Move ₦82,500 to your bank account now?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(Button, 'Request payout'));
    await tester.pumpAndSettle();

    expect(find.text('₦0'), findsOneWidget);
    expect(find.text('₦127,500'), findsOneWidget);
    expect(find.text('−₦82,500'), findsOneWidget);
    expect(find.textContaining('Processing'), findsOneWidget);
  });

  testWidgets('non-designers get the become-a-designer empty state '
      '(web parity)', (tester) async {
    await pump(tester, viewer: 'kiki.adeyemi');

    expect(
      find.text(
        'Earnings are for designer profiles — become a designer '
        'to start earning.',
      ),
      findsOneWidget,
    );
    expect(find.text('Become a designer'), findsOneWidget);
  });

  testWidgets('a designer with no history reads the empty ledger + the '
      'add-account link', (tester) async {
    await pump(tester, viewer: 'tunde.o');

    expect(
      find.text(
        'No payout account yet — requests stay locked until one '
        'is verified.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add account →'), findsOneWidget);
    expect(
      find.text(
        'Payouts and escrow holds will itemize here — publish '
        'outfits to get commissioned.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a lapsed account surfaces the persistent KYC banner', (
    tester,
  ) async {
    final lapsed = EarningsRepositoryFake(
      now: () => pinned,
      resolveDelay: Duration.zero,
    );
    // Pre-pump arrangement loads seed assets — real async, so it must
    // run outside the FakeAsync test zone.
    await tester.runAsync(() async {
      await lapsed.enableDesigner(
        username: 'kiki.adeyemi',
        displayName: 'Kiki Adeyemi',
      );
      await lapsed.attachPayoutAccount('058', '9999999999');
    });
    await pump(tester, repository: lapsed);

    expect(
      find.text(
        'Your payout details lapsed — re-verify to keep '
        'receiving payments.',
      ),
      findsOneWidget,
    );
    expect(find.text('Re-verify'), findsOneWidget);
    expect(find.text('Lapsed'), findsOneWidget);
  });
}
