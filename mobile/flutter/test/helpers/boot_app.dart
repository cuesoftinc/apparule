import 'package:apparule/src/app/app.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/feed/data/media_picker_service.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/routing/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'in_memory_persistence.dart';

/// Boots the full app (router included) over the fake set, optionally
/// seeded — mirrors the entrypoints' composition. [preferences] mocks
/// SharedPreferences (e.g. `{'capture_guide_seen': true}` for a user past
/// the C6 guide's first completion); [persistenceService] swaps the
/// in-memory persistence (seed a session marker for a signed-in cold
/// start, or reuse one instance across pumps to simulate a relaunch).
/// [settle] false stops after the FIRST frame — the boot-flow suite
/// asserts the restore gate before the session value lands.
Future<void> pumpBootedApp(
  WidgetTester tester, {
  AuthRepository? authRepository,
  PersistenceService? persistenceService,
  bool settle = true,
  CameraService? cameraService,
  MediaPickerService? mediaPickerService,
  MeasurementRepository? measurementRepository,
  PostRepository? postRepository,
  OrderRepository? orderRepository,
  NotificationRepository? notificationRepository,
  ProfileRepository? profileRepository,
  EarningsRepository? earningsRepository,
  List<Override> overrides = const <Override>[],
  Map<String, Object> preferences = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...fakeRepositoryOverrides(
          authRepository: authRepository,
          // The secure-storage seam has no plugin in widget tests — the
          // in-memory stand-in keeps the fake auth lifecycle hermetic.
          persistenceService:
              persistenceService ?? InMemoryPersistenceService(),
          cameraService: cameraService,
          mediaPickerService: mediaPickerService,
          measurementRepository: measurementRepository,
          postRepository: postRepository,
          orderRepository: orderRepository,
          notificationRepository: notificationRepository,
          profileRepository: profileRepository,
          earningsRepository: earningsRepository,
        ),
        ...overrides,
      ],
      child: const ApparuleApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// The booted app's router — drives typed-route navigation in tests.
GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(ApparuleApp)),
).read(routerProvider);
