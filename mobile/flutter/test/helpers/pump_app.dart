import 'package:apparule/l10n/generated/app_localizations.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/core/theme/app_theme.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/feed/data/media_picker_service.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import 'in_memory_persistence.dart';

/// Pumps [widget] inside the chrome every screen expects: a ProviderScope
/// over the `*Fake` repositories (mobile-implementation.md §6), the token
/// themes, and the l10n delegates.
///
/// [authRepository] swaps the auth fake (seeded / recording / throwing)
/// and [cameraService] the camera fake (permission-denied / recording)
/// without duplicating their provider overrides;
/// [postRepository]/[orderRepository]/[notificationRepository] likewise
/// swap the feed/orders wave's fakes (pinned clock, empty bundle,
/// role-switched viewer).
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const <Override>[],
    AuthRepository? authRepository,
    CameraService? cameraService,
    MediaPickerService? mediaPickerService,
    MeasurementRepository? measurementRepository,
    PostRepository? postRepository,
    OrderRepository? orderRepository,
    NotificationRepository? notificationRepository,
    ProfileRepository? profileRepository,
    EarningsRepository? earningsRepository,
    PersistenceService? persistenceService,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return pumpWidget(
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
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Bare core/ui modules use ink responses; the transparent
          // Material supplies the required ancestor without changing
          // screen tests (screens bring their own Scaffold).
          home: Material(type: MaterialType.transparency, child: widget),
        ),
      ),
    );
  }
}
