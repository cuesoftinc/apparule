import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_view_model.g.dart';

/// C7's ViewModel — the saved sessions, newest first. Read-only: every
/// vault MUTATION routes through the `VaultActions` façade (the audit's
/// CLASS 1 lock), whose declared fan-out re-derives this provider and
/// the C9 freshness ring together.
@riverpod
class VaultViewModel extends _$VaultViewModel {
  @override
  Future<List<MeasurementSession>> build() =>
      ref.watch(measurementRepositoryProvider).vaultSessions();
}
