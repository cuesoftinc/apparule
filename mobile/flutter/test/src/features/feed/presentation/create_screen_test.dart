import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/feed/presentation/create_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/notched.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('CreateScreen renders its placeholder under fakes', (
    tester,
  ) async {
    await tester.pumpApp(const CreateScreen());
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonPlaceholder), findsOneWidget);
    expect(find.text('Create'), findsWidgets);
    expect(
      find.text(
        'Placeholder screen — the real surface lands with its feature wave.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps content clear of notch and status-bar top insets', (
    tester,
  ) async {
    applyNotchedView(tester);
    await tester.pumpApp(const CreateScreen());
    await tester.pumpAndSettle();
    await expectContentClearOfTopInsets(tester);
  });
}
