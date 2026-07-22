import 'dart:ui';

import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// MI-13 manual entry: advisory ranges (never a hard block), save gated
/// only on having a value, saved sessions land in the vault as
/// `method: manual`.
void main() {
  Future<void> bootToManualEntry(WidgetTester tester) async {
    // Tall surface: four measure rows + the save CTA overflow the
    // default 600px test viewport (the ListView virtualizes the CTA).
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
    );
    routerOf(tester).go(const ManualEntryRoute().location);
    await tester.pumpAndSettle();
  }

  testWidgets('renders the v1 vocabulary and disables save until a value '
      'exists', (tester) async {
    await bootToManualEntry(tester);

    for (final label in <String>[
      'Shoulder Width',
      'Hip Width',
      'Chest Girth',
      'Waist Girth',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    // No value yet → the save CTA is the disabled Button state.
    await tester.tap(find.text('Save to vault'));
    await tester.pumpAndSettle();
    expect(find.byType(VaultScreen), findsNothing);
  });

  testWidgets('saving a value creates a manual vault session', (tester) async {
    await bootToManualEntry(tester);

    await tester.enterText(
      find.bySemanticsLabel('Shoulder Width value'),
      '43',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.tap(find.text('Save to vault'));
    await tester.pumpAndSettle();

    expect(find.byType(VaultScreen), findsOneWidget);
    // The shoulder card re-derives to the just-saved manual value.
    expect(find.text('Measured today'), findsOneWidget);
    expect(find.text('43.0 cm'), findsOneWidget);
    expect(find.text('Manual'), findsWidgets);
  });

  testWidgets('out-of-range values prompt a double-check, never a block', (
    tester,
  ) async {
    await bootToManualEntry(tester);

    await tester.enterText(
      find.bySemanticsLabel('Shoulder Width value'),
      '90',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(
      find.text('Double-check this one — outside the usual 25–75 cm.'),
      findsOneWidget,
    );

    // Advisory only: the save still goes through (bodies vary).
    await tester.tap(find.text('Save to vault'));
    await tester.pumpAndSettle();
    expect(find.byType(VaultScreen), findsOneWidget);
    expect(find.text('90.0 cm'), findsOneWidget);
  });

  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await bootToManualEntry(tester);
    expectNoContentInTopInset(tester);
  });
}
