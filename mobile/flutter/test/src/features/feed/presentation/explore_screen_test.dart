import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/feed/presentation/explore_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('ExploreScreen renders its placeholder under fakes', (
    tester,
  ) async {
    await tester.pumpApp(const ExploreScreen());
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonPlaceholder), findsOneWidget);
    expect(find.text('Explore'), findsWidgets);
    expect(
      find.text(
        'Placeholder screen — the real surface lands with its feature wave.',
      ),
      findsOneWidget,
    );
  });
}
