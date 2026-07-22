import 'package:apparule/src/core/ui/avatar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('Avatar', () {
    testWidgets('renders initials when no image is provided', (tester) async {
      await tester.pumpApp(const Avatar(name: 'Eniola Stitches'));
      expect(find.text('ES'), findsOneWidget);
    });

    testWidgets('username separators drive the initials split', (
      tester,
    ) async {
      await tester.pumpApp(const Avatar(name: 'eniola.stitches'));
      expect(find.text('ES'), findsOneWidget);
    });

    testWidgets('semantics label is the name', (tester) async {
      await tester.pumpApp(const Avatar(name: 'Eniola Stitches'));
      expect(find.bySemanticsLabel('Eniola Stitches'), findsOneWidget);
    });

    testWidgets('designer-verified badge is announced', (tester) async {
      await tester.pumpApp(
        const Avatar(
          name: 'Eniola Stitches',
          badge: AvatarBadge.designerVerified,
        ),
      );
      expect(find.bySemanticsLabel('Verified designer'), findsOneWidget);
    });

    test('freshnessRing maps the MI-11 ladder', () {
      expect(Avatar.freshnessRing('fresh'), AvatarRing.gradient);
      expect(Avatar.freshnessRing('aging'), AvatarRing.amber);
      expect(Avatar.freshnessRing('stale'), AvatarRing.gray);
      expect(Avatar.freshnessRing(null), AvatarRing.gray);
    });
  });
}
