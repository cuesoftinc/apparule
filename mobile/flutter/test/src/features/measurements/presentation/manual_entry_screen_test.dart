import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/manual_entry_view_model.dart';
import 'package:apparule/src/features/measurements/presentation/vault_screen.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';

/// MI-13 manual entry: the A-10 tailor templates select the field set
/// (seeded profile = women; a null template interposes the one-time
/// chooser), advisory ranges (never a hard block), save gated only on
/// having a value, saved sessions land in the vault as `method: manual`.
void main() {
  Future<void> bootToManualEntry(
    WidgetTester tester, {
    ProfileRepositoryFake? profileRepository,
  }) async {
    // Tall surface: the template rows + the save CTA overflow the
    // default 600px test viewport (the ListView virtualizes the CTA).
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      profileRepository: profileRepository,
    );
    routerOf(tester).go(const ManualEntryRoute().location);
    await tester.pumpAndSettle();
  }

  Future<void> scrollToSave(WidgetTester tester) => tester.scrollUntilVisible(
    find.text('Save to vault'),
    120,
    scrollable: find.byType(Scrollable).first,
  );

  testWidgets('renders the seeded women template and disables save until '
      'a value exists', (tester) async {
    await bootToManualEntry(tester);

    // Top of the A-10 women template (flows/vault.md §2) — sentence-case
    // labels; the legacy v1 vocabulary is gone from the sheet.
    for (final label in <String>['Shoulder', 'Bust', 'Under bust']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Shoulder width'), findsNothing);
    expect(find.text('Chest girth'), findsNothing);

    // Every women row exists in the virtualized list (17 measures).
    expect(
      kManualTemplates[MeasurementTemplate.women],
      hasLength(17),
    );

    // No value yet → the save CTA is the disabled Button state.
    await scrollToSave(tester);
    await tester.tap(find.text('Save to vault'));
    await tester.pumpAndSettle();
    expect(find.byType(VaultScreen), findsNothing);
  });

  testWidgets('saving a value creates a manual vault session', (tester) async {
    await bootToManualEntry(tester);

    // Entry is inches by default (A-9): 21 in stores 53.3 canonical cm.
    await tester.enterText(find.bySemanticsLabel('Shoulder value'), '21');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await scrollToSave(tester);
    await tester.tap(find.text('Save to vault'));
    await tester.pumpAndSettle();

    expect(find.byType(VaultScreen), findsOneWidget);
    // The shoulder card re-derives to the just-saved manual value.
    expect(find.text('Measured today'), findsOneWidget);
    expect(find.text('21.0 in'), findsOneWidget);
    expect(find.text('Manual'), findsWidgets);
  });

  testWidgets('out-of-range values prompt a double-check, never a block', (
    tester,
  ) async {
    await bootToManualEntry(tester);

    // 90 in = 228.6 cm — outside the canonical 30–60 cm shoulder
    // advisory; the copy renders the range in the active display unit
    // at one decimal (web/canvas parity).
    await tester.enterText(find.bySemanticsLabel('Shoulder value'), '90');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(
      find.text('Double-check this one — outside the usual 11.8–23.6 in.'),
      findsOneWidget,
    );

    // Advisory only: the save still goes through (bodies vary).
    await scrollToSave(tester);
    await tester.tap(find.text('Save to vault'));
    await tester.pumpAndSettle();
    expect(find.byType(VaultScreen), findsOneWidget);
    expect(find.text('90.0 in'), findsOneWidget);
  });

  testWidgets('a profile without a template gets the one-time chooser; '
      'the pick persists and swaps the rows in', (tester) async {
    final profileRepository = _NoTemplateProfileFake();
    await bootToManualEntry(tester, profileRepository: profileRepository);

    // Chooser replaces the rows — no measure inputs, no save CTA yet.
    expect(find.text('Save to vault'), findsNothing);
    expect(find.text('Shoulder'), findsNothing);

    await tester.tap(find.text('Men’s measurements'));
    await tester.pumpAndSettle();

    // The men template renders in place (14 measures; neck is men-only).
    expect(find.text('Shoulder'), findsOneWidget);
    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Bust'), findsNothing);
    expect(
      kManualTemplates[MeasurementTemplate.men],
      hasLength(14),
    );

    // Persisted (the PATCH /me analogue): the profile now carries it.
    final me = await profileRepository.me();
    expect(me?.measurementTemplate, MeasurementTemplate.men);
  });
}

/// The seeded profile minus its template — reaches the A-10 chooser
/// (assets/seed/dev/me.json carries `"measurement_template": "women"`).
class _NoTemplateProfileFake extends ProfileRepositoryFake {
  MeasurementTemplate? _template;

  @override
  Future<Profile?> me() async {
    final me = await super.me();
    return me?.copyWith(measurementTemplate: _template);
  }

  @override
  Future<Profile> setMeasurementTemplate(MeasurementTemplate template) async {
    _template = template;
    return (await me())!;
  }
}
