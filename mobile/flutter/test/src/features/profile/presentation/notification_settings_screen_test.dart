import 'package:apparule/src/core/ui/app_switch.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/notification_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/notched.dart';

/// B7 Notifications sub-screen: the seven canvas toggles (207:2),
/// persisting through the account repository.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  testWidgets('renders the seven per-event toggles in their seeded '
      'states + the always-sent footer', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repository = ProfileRepositoryFake(now: () => pinned);
    await tester.pumpApp(
      const NotificationSettingsScreen(),
      profileRepository: repository,
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppSwitch), findsNWidgets(7));
    expect(find.text('Quotes & order status'), findsOneWidget);
    expect(find.text('New requests (designers)'), findsOneWidget);
    expect(find.text('Likes & comments'), findsOneWidget);
    expect(find.text('New followers'), findsOneWidget);
    expect(
      find.text('Fresh outfits from people you follow'),
      findsOneWidget,
    );
    expect(find.text('Measurement freshness reminders'), findsOneWidget);
    expect(find.text('Email digest'), findsOneWidget);
    expect(
      find.text(
        'Payment receipts and delivery confirmations are '
        'always sent.',
      ),
      findsOneWidget,
    );

    // Seeded states: new-followers + email-digest start off.
    final switches = tester
        .widgetList<AppSwitch>(find.byType(AppSwitch))
        .toList();
    expect(switches.map((s) => s.value), <bool>[
      true, true, true, false, true, true, false, //
    ]);

    // Toggling persists through the repository (MI-18 optimistic).
    await tester.tap(find.byType(AppSwitch).at(6));
    await tester.pumpAndSettle();
    expect((await repository.me())!.notificationPrefs.emailDigest, isTrue);
  });

  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await tester.pumpApp(
      const NotificationSettingsScreen(),
      profileRepository: ProfileRepositoryFake(now: () => pinned),
    );
    await tester.pumpAndSettle();
    expectNoContentInTopInset(tester);
  });
}
