import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_view_model.g.dart';

/// C7's ViewModel — the saved sessions, newest first (the capture and
/// manual-entry flows invalidate this after a save so the vault lists
/// the new session on arrival).
@riverpod
class VaultViewModel extends _$VaultViewModel {
  @override
  Future<List<MeasurementSession>> build() =>
      ref.watch(measurementRepositoryProvider).vaultSessions();
}
