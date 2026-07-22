import 'package:apparule/src/core/ui/app_switch.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppSwitch', () {
    testWidgets('reports the flipped value on tap', (tester) async {
      bool? changed;
      await tester.pumpApp(
        AppSwitch(value: false, onChanged: (v) => changed = v),
      );

      await tester.tap(find.byType(AppSwitch));
      expect(changed, isTrue);
    });

    testWidgets('null onChanged renders the disabled state (taps '
        'ignored)', (tester) async {
      await tester.pumpApp(const AppSwitch(value: true, onChanged: null));

      await tester.tap(find.byType(AppSwitch));
      expect(
        tester.getSemantics(find.byType(AppSwitch)),
        matchesSemantics(
          hasEnabledState: true,
          hasToggledState: true,
          isToggled: true,
        ),
      );
    });
  });
}
