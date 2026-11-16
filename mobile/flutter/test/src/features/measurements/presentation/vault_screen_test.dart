import 'dart:convert';

import 'package:apparule/src/core/ui/capture_option_card.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/presentation/guide_screen.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// Test harness overrides the platform interface directly without adding it
// as an explicit top-level pubspec dependency.
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

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
    expect(find.text('Up to date · 17 measurements'), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);

    // Metric-centric: one card per A-10 women-template field — the grid
    // virtualizes, so the leading cards + the derived header count (17,
    // asserted above) stand in for an exact widget count.
    expect(find.byType(MeasurementCard, skipOffstage: false), findsWidgets);
    expect(find.text('Shoulder'), findsOneWidget);
    expect(find.text('Bust'), findsOneWidget);

    // Latest values lead their cards (42.5 cm canonical → inches
    // display by default, A-9); the 0.68 waist renders its
    // low-confidence chip (web-parity numbers).
    expect(find.text('16.7 in'), findsOneWidget);
    expect(
      find.text('Low confidence · 0.68', skipOffstage: false),
      findsOneWidget,
    );

    // Consent note + the B4 rights links — below the 17-card grid now,
    // so bring them into the built viewport first.
    await tester.scrollUntilVisible(
      find.text('Download my data'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
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
      're-derives the vault with the "Session deleted" toast (D48)', (
    tester,
  ) async {
    await bootToVault(tester);

    await tester.tap(find.text('Shoulder'));
    await tester.pumpAndSettle();

    // All three seeded sessions carry a shoulder value.
    expect(find.text('Shoulder history'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete session'), findsNWidgets(3));

    // Delete the newest (42.5 cm / 16.7 in) session → the card
    // re-derives to the manual session's 42.2 cm (16.6 in) and the
    // header ages to the 58-day manual.
    await tester.tap(find.bySemanticsLabel('Delete session').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Delete session'), findsNWidgets(2));
    expect(find.text('Session deleted'), findsOneWidget);

    // Dismiss the sheet via its barrier.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('16.6 in'), findsOneWidget);
    expect(find.text('16.7 in'), findsNothing);
    expect(find.text('Measured 58 days ago'), findsOneWidget);
    expect(find.text('Aging · 17 measurements'), findsOneWidget);
  });

  testWidgets('a failed delete rolls back with the shared toast, never '
      'silently (MI-18 / CLASS 4)', (tester) async {
    final repository = MeasurementRepositoryFake();
    await bootToVault(tester, measurementRepository: repository);

    await tester.tap(find.text('Shoulder'));
    await tester.pumpAndSettle();

    repository.failNext = Exception('server 500');
    await tester.tap(find.bySemanticsLabel('Delete session').first);
    await tester.pumpAndSettle();

    // The row stays and the failure toasts.
    expect(find.bySemanticsLabel('Delete session'), findsNWidgets(3));
    expect(find.text('Something went wrong — try again.'), findsOneWidget);
  });

  testWidgets('per-session export sheet offers PDF and CSV; the share sheet '
      'receives the file (PLAT-004, F2-9, #387)', (tester) async {
    final fakeShare = _FakeSharePlatform();
    final originalPlatform = SharePlatform.instance;
    SharePlatform.instance = fakeShare;
    addTearDown(() => SharePlatform.instance = originalPlatform);

    await bootToVault(tester);
    await tester.tap(find.text('Shoulder'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Export session'), findsNWidgets(3));

    // Tap export on the first session -> opens export sheet
    await tester.tap(find.bySemanticsLabel('Export session').first);
    await tester.pumpAndSettle();

    // Export sheet offers PDF and CSV
    expect(find.text('Export session'), findsWidgets);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);

    // Pick PDF
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    // Share sheet receives the PDF file
    expect(fakeShare.lastParams, isNotNull);
    expect(fakeShare.lastParams!.files, hasLength(1));
    expect(fakeShare.lastParams!.fileNameOverrides?.first, endsWith('.pdf'));
    final pdfFile = fakeShare.lastParams!.files!.first;
    expect(pdfFile.mimeType, 'application/pdf');
    final pdfBytes = await pdfFile.readAsBytes();
    final pdfContent = latin1.decode(pdfBytes);
    expect(pdfContent, startsWith('%PDF-1.4'));
    expect(pdfContent, contains('Shoulder: 16.7 in (42.5 cm)'));

    // The history sheet is still open — tap export again to test CSV
    await tester.tap(find.bySemanticsLabel('Export session').first);
    await tester.pumpAndSettle();

    expect(find.text('CSV'), findsOneWidget);
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();

    // Share sheet receives the CSV file
    expect(fakeShare.lastParams!.files, hasLength(1));
    expect(fakeShare.lastParams!.fileNameOverrides?.first, endsWith('.csv'));
    final csvFile = fakeShare.lastParams!.files!.first;
    expect(csvFile.mimeType, 'text/csv');
    final csvContent = await csvFile.readAsString();
    expect(
      csvContent,
      startsWith('Measurement,Inches,Centimetres'),
    );
    expect(csvContent, contains('Shoulder,16.7 in,42.5 cm'));
  });

  testWidgets('top Share button opens the share options sheet offering '
      'Text, PDF, and CSV', (tester) async {
    final fakeShare = _FakeSharePlatform();
    final originalPlatform = SharePlatform.instance;
    SharePlatform.instance = fakeShare;
    addTearDown(() => SharePlatform.instance = originalPlatform);

    await bootToVault(tester);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(find.text('Share measurements'), findsOneWidget);
    expect(find.text('Text message (WhatsApp, SMS)'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);

    // Pick PDF from top share
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(fakeShare.lastParams, isNotNull);
    expect(fakeShare.lastParams!.files, hasLength(1));
    expect(fakeShare.lastParams!.fileNameOverrides?.first, endsWith('.pdf'));
    final pdfBytes = await fakeShare.lastParams!.files!.first.readAsBytes();
    final pdfContent = latin1.decode(pdfBytes);
    expect(pdfContent, startsWith('%PDF-1.4'));
    expect(pdfContent, contains('Shoulder: 16.7 in (42.5 cm)'));
  });

  testWidgets('an empty vault renders the vault EmptyState; its CTA opens '
      'the capture-options sheet — manual entry reachable (D17)', (
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

    await tester.tap(find.text('Take measurement'));
    await tester.pumpAndSettle();
    expect(find.byType(CaptureOptionCard), findsNWidgets(2));

    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();
    expect(find.byType(ManualEntryScreen), findsOneWidget);
  });

  testWidgets('a load error renders recovery copy with Retry — never raw '
      'error text (D47)', (tester) async {
    final repository = _FailingVaultRepository();
    await bootToVault(tester, measurementRepository: repository);
    repository.healed = true;

    expect(
      find.text("The vault couldn't load — try again"),
      findsOneWidget,
    );
    expect(find.textContaining('Exception'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyState), findsOneWidget);
  });
  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToVault(tester);
    await expectContentClearOfTopInsets(tester);
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}

/// The vault list fails until [healed] (a flaky network read), then
/// serves the empty vault — the D47 Retry path's fixture. Healing is
/// caller-controlled because other providers (the C9 freshness
/// derivation) also read the vault at boot in nondeterministic order.
class _FailingVaultRepository extends MeasurementRepositoryFake {
  _FailingVaultRepository() : super(bundle: _EmptyAssetBundle());

  bool healed = false;

  @override
  Future<List<MeasurementSession>> vaultSessions() {
    if (!healed) throw Exception('server 500');
    return super.vaultSessions();
  }
}

class _FakeSharePlatform extends SharePlatform {
  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    lastParams = params;
    return const ShareResult('success', ShareResultStatus.success);
  }
}
