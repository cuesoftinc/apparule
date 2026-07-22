import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('QCHintChip', () {
    testWidgets('renders the canonical guidance copy', (tester) async {
      await tester.pumpApp(const QCHintChip(code: QcFailCode.tooFar));
      expect(
        find.text('Move closer — fill more of the frame'),
        findsOneWidget,
      );

      await tester.pumpApp(const QCHintChip(code: QcFailCode.notFrontal));
      expect(find.text('Face the camera straight on'), findsOneWidget);
    });

    test('wire codes round-trip through fromWireName', () {
      expect(
        QcFailCode.fromWireName('not_frontal'),
        QcFailCode.notFrontal,
      );
      for (final code in QcFailCode.values) {
        expect(QcFailCode.fromWireName(code.wireName), code);
      }
    });

    test('unknown wire codes map to null (additive-schema safe)', () {
      expect(QcFailCode.fromWireName('unknown_code'), isNull);
    });
  });
}
