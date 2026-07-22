import 'package:apparule/src/core/ui/app_switch.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/privacy_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/notched.dart';
import '../../../../helpers/pump_app.dart';

/// B7 Privacy & consent sub-screen (207:7155): AI-processing + nearby
/// toggles, the retention notice, the seeded consent ledger.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  testWidgets('renders toggles, retention copy and the consent ledger '
      'off the pinned clock', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repository = ProfileRepositoryFake(now: () => pinned);
    await tester.pumpApp(
      const PrivacySettingsScreen(),
      profileRepository: repository,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Process my photos to estimate measurements'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Required for camera capture. Manual entry stays '
        'available if you turn this off.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Capture photos are deleted automatically 30 '
        'days after a session is saved.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Use my city for nearby recommendations'),
      findsOneWidget,
    );
    // Consent seeds 40d before the pinned Jul 22 clock → Jun 12.
    expect(
      find.text('Terms of service — accepted Jun 12, 2026'),
      findsOneWidget,
    );
    expect(
      find.text('Privacy policy — accepted Jun 12, 2026'),
      findsOneWidget,
    );
    expect(find.text('Read the privacy policy →'), findsOneWidget);

    // Turning AI processing off persists (capture consent gate).
    await tester.tap(find.byType(AppSwitch).first);
    await tester.pumpAndSettle();
    expect((await repository.me())!.privacyPrefs.aiProcessing, isFalse);
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await tester.pumpApp(
      const PrivacySettingsScreen(),
      profileRepository: ProfileRepositoryFake(now: () => pinned),
    );
    await tester.pumpAndSettle();
    await expectContentClearOfTopInsets(tester);
  });
}
