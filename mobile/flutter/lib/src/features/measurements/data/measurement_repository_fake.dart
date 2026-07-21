import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';

/// Empty-state fake — the seeded §6 narrative (assets/seed/) arrives with
/// the screens wave; the interface seam is what this wave establishes.
class MeasurementRepositoryFake implements MeasurementRepository {
  @override
  Future<List<MeasurementSession>> vaultSessions() async =>
      const <MeasurementSession>[];
}
