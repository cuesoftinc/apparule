import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('SignInScreen renders its placeholder under fakes', (
    tester,
  ) async {
    await tester.pumpApp(const SignInScreen());
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonPlaceholder), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(
      find.text(
        'Placeholder screen — the real surface lands with its feature wave.',
      ),
      findsOneWidget,
    );
  });
}
