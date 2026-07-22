import 'package:apparule/src/app/app.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/routing/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the full app (router included) over the fake set, optionally
/// seeded — mirrors the entrypoints' composition. [preferences] mocks
/// SharedPreferences (e.g. `{'capture_guide_seen': true}` for a user past
/// the C6 guide's first completion).
Future<void> pumpBootedApp(
  WidgetTester tester, {
  AuthRepository? authRepository,
  CameraService? cameraService,
  MeasurementRepository? measurementRepository,
  PostRepository? postRepository,
  OrderRepository? orderRepository,
  NotificationRepository? notificationRepository,
  List<Override> overrides = const <Override>[],
  Map<String, Object> preferences = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...fakeRepositoryOverrides(
          authRepository: authRepository,
          cameraService: cameraService,
          measurementRepository: measurementRepository,
          postRepository: postRepository,
          orderRepository: orderRepository,
          notificationRepository: notificationRepository,
        ),
        ...overrides,
      ],
      child: const ApparuleApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// The booted app's router — drives typed-route navigation in tests.
GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(ApparuleApp)),
).read(routerProvider);
