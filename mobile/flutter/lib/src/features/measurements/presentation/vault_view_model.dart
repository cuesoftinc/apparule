import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_view_model.g.dart';

/// C7 placeholder ViewModel — watches the abstract measurement
/// repository; dev/stg overrides supply the fake.
@riverpod
class VaultViewModel extends _$VaultViewModel {
  @override
  Future<List<MeasurementSession>> build() =>
      ref.watch(measurementRepositoryProvider).vaultSessions();
}
