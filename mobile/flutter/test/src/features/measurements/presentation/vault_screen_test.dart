import 'package:apparule/src/core/ui/capture_option_card.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C7 over the seeded fake (canvas 173:698): the MI-11 freshness-ring
/// header with the Retake capture-options sheet, one MeasurementCard per
/// METRIC (latest value + sparkline history, tap → history sheet with
/// per-session delete), and the consent note with the B4 rights links.
void main() {
  Future<void> bootToVault(
    WidgetTester tester, {
    MeasurementRepositoryFake? measurementRepository,
    Map<String, Object> preferences = const <String, Object>{},
  }) async {
    // Tall surface: the ListView virtualizes below the default 600px.
    tester.view.physicalSize = const Size(800, 1700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      measurementRepository: measurementRepository,
      preferences: preferences,
    );
    routerOf(tester).go(const VaultRoute().location);
    await tester.pumpAndSettle();
  }

  testWidgets('renders the freshness header and one card per metric with '
      'the latest value', (tester) async {
    await bootToVault(tester);

    // Newest seeded session is the 12-day scan → fresh header.
    expect(find.text('Measured 12 days ago'), findsOneWidget);
    expect(find.text('Up to date · 4 measurements'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);

    // Metric-centric: 4 distinct measures across the 3 seeded sessions.
    expect(find.byType(MeasurementCard), findsNWidgets(4));

    // Latest values lead their cards; the 0.62 hip renders its
    // low-confidence chip (web-parity numbers).
    expect(find.text('42.5 cm'), findsOneWidget);
    expect(find.text('Low confidence · 0.62'), findsOneWidget);

    // Consent note + the B4 rights links.
    expect(
      find.text(
        'Sessions are kept until you delete them. A snapshot is shared '
        'only when you send a request.',
      ),
      findsOneWidget,
    );
    expect(find.text('Download my data'), findsOneWidget);
    expect(find.text('Delete all measurements'), findsOneWidget);
  });

  testWidgets('Retake opens the capture-options sheet; the camera card '
      'launches the capture flow (guide on first run)', (tester) async {
    await bootToVault(tester);

    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();

    expect(find.text('Retake your measurements'), findsOneWidget);
    expect(find.byType(CaptureOptionCard), findsNWidgets(2));

    await tester.tap(find.text('Use your camera'));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureGuideScreen), findsOneWidget);
  });

  testWidgets('the manual option card opens manual entry', (tester) async {
    await bootToVault(tester);

    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();

    expect(find.byType(ManualEntryScreen), findsOneWidget);
  });

  testWidgets('tapping a card opens its history sheet; deleting a session '
      're-derives the vault', (tester) async {
    await bootToVault(tester);

    await tester.tap(find.text('Shoulder Width'));
    await tester.pumpAndSettle();

    // All three seeded sessions carry a shoulder value.
    expect(find.text('Shoulder Width history'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete session'), findsNWidgets(3));

    // Delete the newest (42.5) session → the card re-derives to the
    // manual session's 42.0 and the header ages to the 58-day manual.
    await tester.tap(find.bySemanticsLabel('Delete session').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Delete session'), findsNWidgets(2));

    // Dismiss the sheet via its barrier.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('42.0 cm'), findsOneWidget);
    expect(find.text('42.5 cm'), findsNothing);
    expect(find.text('Measured 58 days ago'), findsOneWidget);
    expect(find.text('Aging · 4 measurements'), findsOneWidget);
  });

  testWidgets('an empty vault renders the vault EmptyState alone', (
    tester,
  ) async {
    await bootToVault(
      tester,
      measurementRepository: MeasurementRepositoryFake(
        bundle: _EmptyAssetBundle(),
      ),
    );

    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.text('No measurements yet — take your first scan'),
      findsOneWidget,
    );
    // Canvas 212:5925: the capture options live behind the CTA, not
    // above the empty state.
    expect(find.byType(CaptureOptionCard), findsNothing);
  });
  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToVault(tester);
    expectNoContentInTopInset(tester);
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
