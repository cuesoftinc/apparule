import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C9 edit profile (canvas 532:2): hydrates from the account, persists
/// display fields + the optional location, pops back to the profile
/// tab. Bio is designer-scoped ["follow web" ruling 2026-07-22].
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Future<ProfileRepositoryFake> bootToEdit(
    WidgetTester tester, {
    EarningsRepositoryFake? earningsRepository,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final repository = ProfileRepositoryFake(now: () => pinned);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      profileRepository: repository,
      earningsRepository: earningsRepository,
    );
    routerOf(tester).go(const EditProfileRoute().location);
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('hydrates the form and persists edits through the '
      'repository — no bio field for the non-designer viewer', (
    tester,
  ) async {
    final repository = await bootToEdit(tester);

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Kiki Adeyemi'), findsOneWidget);
    // Bio is designer-only (web parity: no account-level bio edit) —
    // kiki is the seeded non-designer.
    expect(find.text('Bio'), findsNothing);
    expect(find.widgetWithText(TextField, 'Lagos'), findsNWidgets(2));
    expect(
      find.text('Optional — used to recommend nearby designers.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Kiki Adeyemi'),
      'Kiki A.',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final me = await repository.me();
    expect(me!.displayName, 'Kiki A.');
    expect(me.location?.city, 'Lagos');
    // The hidden bio saves back unchanged.
    expect(me.bio, 'aso-ebi sets & bridal');
  });

  testWidgets('a designer session gets the bio field and persists it', (
    tester,
  ) async {
    final repository = await bootToEdit(
      tester,
      earningsRepository: EarningsRepositoryFake(viewer: 'amara.designs'),
    );

    expect(find.text('Bio'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'aso-ebi sets & bridal'),
      'bridal & occasion wear',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final me = await repository.me();
    expect(me!.bio, 'bridal & occasion wear');
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await pumpBootedApp(
      tester,
      authRepository: AuthRepositoryFake(
        initialSession: AuthRepositoryFake.seedSession,
      ),
      profileRepository: ProfileRepositoryFake(now: () => pinned),
    );
    routerOf(tester).go(const EditProfileRoute().location);
    await tester.pumpAndSettle();
    await expectContentClearOfTopInsets(tester);
  });
}
