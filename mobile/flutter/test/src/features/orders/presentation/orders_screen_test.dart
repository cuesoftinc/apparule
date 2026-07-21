import 'package:apparule/src/core/ui/skeleton_placeholder.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('OrdersScreen renders its placeholder under fakes', (
    tester,
  ) async {
    await tester.pumpApp(const OrdersScreen());
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonPlaceholder), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
    expect(
      find.text(
        'Placeholder screen — the real surface lands with its feature wave.',
      ),
      findsOneWidget,
    );
  });
}
