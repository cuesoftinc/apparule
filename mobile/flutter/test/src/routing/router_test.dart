import 'package:apparule/src/app/app.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/features/feed/presentation/create_screen.dart';
import 'package:apparule/src/features/feed/presentation/explore_screen.dart';
import 'package:apparule/src/features/feed/presentation/home_feed_screen.dart';
import 'package:apparule/src/features/orders/presentation/orders_screen.dart';
import 'package:apparule/src/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the five tabs navigate to their branch screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeRepositoryOverrides(),
        child: const ApparuleApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Home is the initial branch.
    expect(find.byType(HomeFeedScreen), findsOneWidget);

    // Tap each remaining tab via its (unselected, outline) icon — the
    // filled variant marks the active tab (IG convention, design.md §2).
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_box_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(CreateScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.receipt_long_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline).last);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });
}
