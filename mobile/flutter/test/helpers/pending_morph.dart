import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:flutter_test/flutter_test.dart';

/// The MI-18 pending-future morph recipe (the interaction audit's
/// CLASS 2 lock): arm the repository so the mutation's future NEVER
/// resolves during the test (a `Completer.future` behind the fake), tap,
/// pump ONE frame, and assert the morph already landed with no skeleton
/// anywhere — optimism that waits for the round-trip, or an
/// invalidate-to-loading flash, both fail here.
///
/// ```dart
/// final gate = Completer<void>();            // never completed
/// // …override the repo so setFollow/toggleLike awaits gate.future…
/// await expectMorphsWhilePending(
///   tester,
///   trigger: find.text('Follow'),
///   expectMorphed: () => expect(find.text('Following'), findsOneWidget),
/// );
/// ```
Future<void> expectMorphsWhilePending(
  WidgetTester tester, {
  required Finder trigger,
  required void Function() expectMorphed,
}) async {
  await tester.tap(trigger);
  // ONE frame — the repository future is still pending.
  await tester.pump();
  expectMorphed();
  expectNoSkeletons();
}

/// No skeleton may be on screen mid-mutation: an optimistic surface
/// never drops rendered content back to loading (`skipLoadingOnRefresh`
/// / `valueOrNull` body switches — CLASS 2's D28 half).
void expectNoSkeletons() {
  expect(
    find.byType(Skeleton),
    findsNothing,
    reason: 'an optimistic mutation must never skeleton the surface',
  );
  expect(
    find.byType(SkeletonPlaceholder),
    findsNothing,
    reason: 'an optimistic mutation must never skeleton the surface',
  );
}
