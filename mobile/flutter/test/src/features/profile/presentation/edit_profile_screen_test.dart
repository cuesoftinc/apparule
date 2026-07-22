import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/boot_app.dart';
import '../../../../helpers/notched.dart';

/// C9 edit profile: hydrates from the account, persists display
/// fields + the optional location, pops back to the profile tab.
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  testWidgets('hydrates the form and persists edits through the '
      'repository', (tester) async {
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
    );
    routerOf(tester).go(const EditProfileRoute().location);
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Kiki Adeyemi'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'aso-ebi sets & bridal'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Lagos'), findsNWidgets(2));
    expect(
      find.text('Optional — used to recommend nearby designers.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'aso-ebi sets & bridal'),
      'bridal & occasion wear',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final me = await repository.me();
    expect(me!.bio, 'bridal & occasion wear');
    expect(me.location?.city, 'Lagos');
  });

  testWidgets('keeps content clear of the notched top inset', (
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
    expectNoContentInTopInset(tester);
  });
}
