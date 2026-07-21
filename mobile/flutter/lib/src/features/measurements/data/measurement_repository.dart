import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'measurement_repository.g.dart';

/// Abstract measurement repository — the vault (C7) and capture results
/// (C6) read/write through it (mobile-implementation.md §10).
abstract class MeasurementRepository {
  /// All vault sessions for the signed-in user (C7).
  Future<List<MeasurementSession>> vaultSessions();
}

/// Overridden per entrypoint (di.dart) — no default implementation exists
/// until the API wave lands `*Remote` (mobile-implementation.md §6).
@Riverpod(keepAlive: true)
MeasurementRepository measurementRepository(Ref ref) =>
    throw UnimplementedError(
      'measurementRepository must be overridden with a *Fake or *Remote '
      'implementation (mobile-implementation.md §6)',
    );
