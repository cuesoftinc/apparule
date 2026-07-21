import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/profile/presentation/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('ProfileScreen renders its placeholder under fakes', (
    tester,
  ) async {
    await tester.pumpApp(const ProfileScreen());
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonPlaceholder), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
    expect(
      find.text(
        'Placeholder screen — the real surface lands with its feature wave.',
      ),
      findsOneWidget,
    );
  });
}
