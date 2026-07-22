import 'package:apparule/l10n/generated/app_localizations.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import 'in_memory_persistence.dart';

/// Frames a SCREEN for a golden scenario: phone-sized box, the fake
/// provider set, and the l10n delegates (alchemist's harness supplies the
/// MaterialApp + theme around this).
Widget screenFrame(
  Widget screen, {
  List<Override> overrides = const <Override>[],
  AuthRepository? authRepository,
  CameraService? cameraService,
  MeasurementRepository? measurementRepository,
  PostRepository? postRepository,
  OrderRepository? orderRepository,
  NotificationRepository? notificationRepository,
  ProfileRepository? profileRepository,
  EarningsRepository? earningsRepository,
}) {
  return ProviderScope(
    overrides: <Override>[
      ...fakeRepositoryOverrides(
        authRepository: authRepository,
        // The secure-storage seam has no plugin in golden runs — the
        // in-memory stand-in keeps the fake auth lifecycle hermetic.
        persistenceService: InMemoryPersistenceService(),
        cameraService: cameraService,
        measurementRepository: measurementRepository,
        postRepository: postRepository,
        orderRepository: orderRepository,
        notificationRepository: notificationRepository,
        profileRepository: profileRepository,
        earningsRepository: earningsRepository,
      ),
      ...overrides,
    ],
    child: Localizations(
      locale: const Locale('en'),
      delegates: AppLocalizations.localizationsDelegates,
      child: SizedBox(width: 390, height: 844, child: screen),
    ),
  );
}
