import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/feed/data/post_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/profile/data/profile_repository_fake.dart';
import 'package:apparule/src/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../../../helpers/notched.dart';
import '../../../../helpers/pump_app.dart';

/// C9 own profile: the vault-ring header, graph-derived counts, the
/// grid/saved tabs over the liked/saved projections (pages.md C9).
void main() {
  final pinned = DateTime.utc(2026, 7, 22, 12);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpApp(
      const ProfileScreen(),
      postRepository: PostRepositoryFake(now: () => pinned),
      profileRepository: ProfileRepositoryFake(now: () => pinned),
      measurementRepository: MeasurementRepositoryFake(now: () => pinned),
      earningsRepository: EarningsRepositoryFake(
        now: () => pinned,
        resolveDelay: Duration.zero,
      ),
      overrides: <Override>[
        clockProvider.overrideWith(
          (ref) =>
              () => pinned,
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the seeded header: identity, meta line, counts '
      'off the graph', (tester) async {
    await pump(tester);

    expect(find.text('kiki.adeyemi'), findsOneWidget);
    expect(find.text('Kiki Adeyemi'), findsOneWidget);
    expect(
      find.text('Lagos · aso-ebi sets & bridal · vault is private'),
      findsOneWidget,
    );
    // Non-designer: 0 posts, 0 followers, following mirrors the graph.
    expect(find.text('posts'), findsOneWidget);
    expect(find.text('followers'), findsOneWidget);
    expect(find.text('following'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Measurement vault'), findsOneWidget);
  });

  testWidgets('the header avatar carries the MI-11 freshness ring — the '
      'C7 entry', (tester) async {
    await pump(tester);

    final avatar = tester.widget<Avatar>(find.byType(Avatar));
    // The seeded vault's newest session is fresh (<30d) → gradient.
    expect(avatar.ring, AvatarRing.gradient);
    expect(avatar.size, AvatarSize.s96);
    expect(
      find.bySemanticsLabel('Open your measurement vault'),
      findsOneWidget,
    );
  });

  testWidgets('the C10 bell and the settings gear ride the app bar', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byIcon(LucideIcons.bell), findsOneWidget);
    expect(find.byIcon(LucideIcons.settings), findsOneWidget);
  });

  testWidgets('grid tabs: liked projection first, saved on the second '
      '(viewer-private)', (tester) async {
    await pump(tester);

    // kiki's liked set seeds 3 posts.
    expect(find.byType(Image), findsNWidgets(3));

    await tester.tap(find.byIcon(LucideIcons.bookmark));
    await tester.pumpAndSettle();
    // Saved set seeds 2.
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await pump(tester);
    await expectContentClearOfTopInsets(tester);
  });
}
