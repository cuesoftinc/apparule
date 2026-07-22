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

/// C7 over the seeded fake: the web-parity session narrative renders with
/// source chips, confidences, and freshness labels; the capture-entry
/// cards route into C6.
void main() {
  Future<void> bootToVault(
    WidgetTester tester, {
    MeasurementRepositoryFake? measurementRepository,
    Map<String, Object> preferences = const <String, Object>{},
  }) async {
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

  testWidgets('lists the seeded §6 sessions with values, confidences and '
      'freshness labels', (tester) async {
    // Tall surface: the ListView virtualizes below the default 600px.
    tester.view.physicalSize = const Size(800, 1700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await bootToVault(tester);

    // Three seeded sessions: recent scan, manual tape, old scan —
    // eight measurement rows between them (web seed parity).
    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Measured 12d ago'), findsOneWidget);
    expect(find.text('Measured 58d ago'), findsOneWidget);
    expect(find.text('Measured 140d ago'), findsOneWidget);
    expect(find.byType(MeasurementCard), findsNWidgets(8));

    // Web-parity numbers; the 0.62 hip renders its low-confidence chip.
    expect(find.text('42.5 cm'), findsOneWidget);
    expect(find.text('Low confidence · 0.62'), findsOneWidget);
  });

  testWidgets('the camera option card launches the capture flow (guide on '
      'first run)', (tester) async {
    await bootToVault(tester);

    await tester.tap(find.text('Use your camera'));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureGuideScreen), findsOneWidget);
  });

  testWidgets('the manual option card opens manual entry', (tester) async {
    await bootToVault(tester);

    await tester.tap(find.text('Enter manually'));
    await tester.pumpAndSettle();

    expect(find.byType(ManualEntryScreen), findsOneWidget);
  });

  testWidgets('an empty vault renders the vault EmptyState', (tester) async {
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
    expect(find.byType(CaptureOptionCard), findsNWidgets(2));
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
