import 'package:apparule/src/core/ui/banner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppBanner', () {
    testWidgets('persistent banners carry no dismiss control', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppBanner(message: 'Measurements are 47 days old.'),
      );

      expect(find.text('Measurements are 47 days old.'), findsOneWidget);
      expect(find.bySemanticsLabel('Dismiss'), findsNothing);
    });

    testWidgets('dismissable banners remove themselves and notify', (
      tester,
    ) async {
      var dismissed = 0;
      await tester.pumpApp(
        AppBanner(
          message: 'Payout verification lapsed.',
          dismissable: true,
          onDismiss: () => dismissed++,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Dismiss'));
      await tester.pump();

      expect(dismissed, 1);
      expect(find.text('Payout verification lapsed.'), findsNothing);
    });

    testWidgets('the action-link slot fires onAction', (tester) async {
      var actions = 0;
      await tester.pumpApp(
        AppBanner(
          message: 'Payout verification lapsed.',
          tone: BannerTone.warn,
          actionLabel: 'Re-verify',
          onAction: () => actions++,
        ),
      );

      await tester.tap(find.text('Re-verify'));
      await tester.pump();

      expect(actions, 1);
    });
  });
}
