import 'package:apparule/src/core/ui/confetti_burst.dart';
import 'package:apparule/src/core/ui/edge_resist_physics.dart';
import 'package:apparule/src/core/ui/flip_unit_toggle.dart';
import 'package:apparule/src/core/ui/gradient_refresh_spinner.dart';
import 'package:apparule/src/core/ui/manual_measure_row.dart';
import 'package:apparule/src/core/ui/morph_swap.dart';
import 'package:apparule/src/core/ui/spring_badge.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/core/ui/step_slide.dart';
import 'package:apparule/src/core/ui/tab_bar.dart';
import 'package:apparule/src/core/ui/timeline_connector.dart';
import 'package:apparule/src/core/ui/typing_bubble.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/auth/data/auth_repository_fake.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'boot_app.dart';
import 'pump_app.dart';

/// One screen×MI row of the conformance registry (the interaction
/// audit's CLASS 6 lock): pages.md marks the MI active on the screen,
/// so the screen must INSTANTIATE the named core/ui primitive — an MI
/// can no longer ship as "active" while absent.
///
/// [pump] drives the screen to the state where the primitive renders;
/// while a lane still owns the wiring the row carries [pendingOwner]
/// instead and registers as a skipped test — the visible ledger. A lane
/// wires the MI, moves the row to `pump`, and the harness enforces it
/// forever after.
class MiRegistryEntry {
  const MiRegistryEntry({
    required this.screen,
    required this.mi,
    required this.primitive,
    this.pump,
    this.pendingOwner,
  }) : assert(
         (pump == null) != (pendingOwner == null),
         'a row is either wired (pump) or pending (pendingOwner)',
       );

  /// The pages.md surface ("C2 Home feed").
  final String screen;

  /// The design.md §4 row ("MI-5 pull-to-refresh").
  final String mi;

  /// The named core/ui primitive type the screen must instantiate.
  final Type primitive;

  /// Drives the screen to where the primitive is on stage.
  final Future<void> Function(WidgetTester tester)? pump;

  /// The fix-wave lane that owns the wiring while pending.
  final String? pendingOwner;
}

/// The screen→active-MI table, derived from pages.md Part C and the
/// design.md §4 catalog. Wave 0 wires the shell badge and the C5
/// success burst; each lane flips its rows from pending to pumped as it
/// lands them.
final List<MiRegistryEntry> miRegistry = <MiRegistryEntry>[
  MiRegistryEntry(
    screen: 'shell tab bar',
    mi: 'MI-16 badge spring',
    primitive: SpringBadge,
    pump: (tester) async {
      await tester.pumpApp(
        AppTabBar(active: AppTab.home, onSelect: (_) {}, ordersBadge: 3),
      );
    },
  ),
  MiRegistryEntry(
    screen: 'C5 request stepper — success',
    mi: 'MI-10 confetti burst',
    primitive: ConfettiBurst,
    pump: (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpBootedApp(
        tester,
        authRepository: AuthRepositoryFake(
          initialSession: AuthRepositoryFake.seedSession,
        ),
      );
      routerOf(
        tester,
      ).go(const RequestRoute(postId: 'post-ankara-gown').location);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(StatusPill),
          matching: find.text('Fresh'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit request'));
      await tester.pumpAndSettle();
    },
  ),
  // -- pending rows: the lanes' wiring ledger -------------------------------
  const MiRegistryEntry(
    screen: 'C2 home feed',
    mi: 'MI-5 pull-to-refresh',
    primitive: GradientRefreshSpinner,
    pendingOwner: 'LANE A (D28)',
  ),
  const MiRegistryEntry(
    screen: 'C3 explore',
    mi: 'MI-5 pull-to-refresh',
    primitive: GradientRefreshSpinner,
    pendingOwner: 'LANE A (D25)',
  ),
  const MiRegistryEntry(
    screen: 'C2/C4 post card carousel',
    mi: 'MI-4 edge-resist',
    primitive: EdgeResistPhysics,
    pendingOwner: 'LANE A (D59)',
  ),
  const MiRegistryEntry(
    screen: 'C9/C12 user rows',
    mi: 'MI-7 150ms follow morph',
    primitive: MorphSwap,
    pendingOwner: 'LANE A (D55)',
  ),
  const MiRegistryEntry(
    screen: 'C8 order thread',
    mi: 'MI-17 responding pulse',
    primitive: TypingBubble,
    pendingOwner: 'LANE B (D13)',
  ),
  const MiRegistryEntry(
    screen: 'C8 order timeline',
    mi: 'MI-14 connector draw + pulse',
    primitive: TimelineConnector,
    pendingOwner: 'LANE B (D41)',
  ),
  const MiRegistryEntry(
    screen: 'C5 request stepper — steps',
    mi: 'MI-10 24px step slide',
    primitive: StepSlide,
    pendingOwner: 'LANE B (D62)',
  ),
  MiRegistryEntry(
    screen: 'C6 manual measure row',
    mi: 'MI-13 unit flip',
    primitive: FlipUnitToggle,
    pump: (tester) async {
      await tester.pumpApp(
        Center(
          child: SizedBox(
            width: 358,
            child: ManualMeasureRow(
              name: 'shoulder_width',
              valueCm: 43,
              unit: MeasureUnit.cm,
              onChanged: (_) {},
              onUnitChanged: (_) {},
            ),
          ),
        ),
      );
    },
  ),
];
