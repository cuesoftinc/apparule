import 'package:apparule/l10n/generated/app_localizations.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/orders/data/order_repository.dart';
import 'package:apparule/src/features/profile/data/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

/// Frames a SCREEN for a golden scenario: phone-sized box, the fake
/// provider set, and the l10n delegates (alchemist's harness supplies the
/// MaterialApp + theme around this).
Widget screenFrame(
  Widget screen, {
  List<Override> overrides = const <Override>[],
  CameraService? cameraService,
  MeasurementRepository? measurementRepository,
  PostRepository? postRepository,
  OrderRepository? orderRepository,
  NotificationRepository? notificationRepository,
}) {
  return ProviderScope(
    overrides: <Override>[
      ...fakeRepositoryOverrides(
        cameraService: cameraService,
        measurementRepository: measurementRepository,
        postRepository: postRepository,
        orderRepository: orderRepository,
        notificationRepository: notificationRepository,
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
