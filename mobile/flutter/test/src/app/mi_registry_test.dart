import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mi_registry.dart';

/// The MI-registry conformance harness (the interaction audit's CLASS 6
/// lock): every registry row whose wiring has landed pumps its screen
/// and asserts the named core/ui primitive is INSTANTIATED — a screen
/// can no longer ship with an MI marked active in pages.md but absent
/// on stage. Pending rows register as skipped tests: the visible
/// wiring ledger the lanes burn down (flip `pendingOwner` to `pump` as
/// each lands).
void main() {
  for (final entry in miRegistry) {
    final title =
        '${entry.screen} instantiates ${entry.primitive} (${entry.mi})';
    if (entry.pump case final pump?) {
      testWidgets(title, (tester) async {
        await pump(tester);
        expect(
          find.byType(entry.primitive, skipOffstage: false),
          findsWidgets,
          reason:
              '${entry.screen} marks ${entry.mi} active — the '
              '${entry.primitive} primitive must be on stage',
        );
      });
    } else {
      // The visible ledger: skipped until the owning lane wires it.
      testWidgets(
        '$title — pending ${entry.pendingOwner}',
        (tester) async {},
        skip: true,
      );
    }
  }
}
