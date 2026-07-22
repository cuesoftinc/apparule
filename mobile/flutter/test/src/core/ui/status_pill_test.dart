import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('StatusPill', () {
    testWidgets('labels render in sentence case', (tester) async {
      await tester.pumpApp(
        const StatusPill(status: StatusPillValue.inProgress),
      );
      expect(find.text('In progress'), findsOneWidget);

      await tester.pumpApp(
        const StatusPill(status: StatusPillValue.requested),
      );
      expect(find.text('Requested'), findsOneWidget);

      await tester.pumpApp(const StatusPill(status: StatusPillValue.fresh));
      expect(find.text('Fresh'), findsOneWidget);
    });

    testWidgets('status changes crossfade + pulse without throwing (MI-14)', (
      tester,
    ) async {
      await tester.pumpApp(const StatusPill(status: StatusPillValue.paid));
      await tester.pumpApp(
        const StatusPill(status: StatusPillValue.shipped),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(tester.takeException(), isNull);
      expect(find.text('Shipped'), findsOneWidget);
    });
  });
}
