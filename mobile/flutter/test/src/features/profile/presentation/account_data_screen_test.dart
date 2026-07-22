import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/account_data_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/notched.dart';

/// B7 Account & data (207:7182) + the delete ladder (207:7204):
/// export-first, quiet-danger arming, the typed-confirm gate, and the
/// honest deletion-pending mutation.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Future<ProfileRepositoryFake> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repository = ProfileRepositoryFake(now: () => pinned);
    await tester.pumpApp(
      const AccountDataScreen(),
      profileRepository: repository,
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('renders identity, export-first and the danger zone', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Signed in with Google'), findsOneWidget);
    expect(find.text('kiki.adeyemi@example.com'), findsOneWidget);
    expect(find.text('Download my data'), findsOneWidget);
    expect(
      find.text(
        'Measurements, sessions, posts and orders as JSON — '
        "we'll email a link within 24 hours.",
      ),
      findsOneWidget,
    );
    expect(find.text('Danger zone'), findsOneWidget);
    expect(find.text('Delete account & all data'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    // The row-level rung is quiet-danger, never filled destructive.
    final deleteButton = tester.widget<Button>(
      find.widgetWithText(Button, 'Delete account & all data'),
    );
    expect(deleteButton.kind, ButtonKind.quietDanger);
  });

  testWidgets('export confirms with the email-a-link snack', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Download my data'));
    await tester.pumpAndSettle();
    expect(
      find.text("Export requested — we'll email a link within 24 hours."),
      findsOneWidget,
    );
  });

  testWidgets('the delete ladder: typed DELETE gates the filled '
      'confirm; confirming flips deletion-pending', (tester) async {
    final repository = await pump(tester);

    await tester.tap(find.text('Delete account & all data'));
    await tester.pumpAndSettle();

    expect(find.text('Delete your account?'), findsOneWidget);
    expect(find.text('Export everything first'), findsOneWidget);
    // The confirm arms only on the typed keyword.
    Button confirm() => tester.widget<Button>(
      find.widgetWithText(Button, 'Permanently delete everything'),
    );
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delete me');
    await tester.pumpAndSettle();
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.text('Permanently delete everything'));
    await tester.pumpAndSettle();

    expect((await repository.me())!.deletionPending, isTrue);
    // The screen re-renders pending: banner + disarmed danger row.
    expect(
      find.textContaining('Account deletion requested'),
      findsOneWidget,
    );
    final dangerRow = tester.widget<Button>(
      find.widgetWithText(Button, 'Delete account & all data'),
    );
    expect(dangerRow.onPressed, isNull);
  });

  testWidgets('cancel and the export hatch leave the account intact', (
    tester,
  ) async {
    final repository = await pump(tester);

    await tester.tap(find.text('Delete account & all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((await repository.me())!.deletionPending, isFalse);

    await tester.tap(find.text('Delete account & all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export everything first'));
    await tester.pumpAndSettle();
    expect((await repository.me())!.deletionPending, isFalse);
    expect(
      find.text("Export requested — we'll email a link within 24 hours."),
      findsOneWidget,
    );
  });

  testWidgets('keeps content clear of the notched top inset', (
    tester,
  ) async {
    applyNotchedView(tester);
    await pump(tester);
    expectNoContentInTopInset(tester);
  });
}
