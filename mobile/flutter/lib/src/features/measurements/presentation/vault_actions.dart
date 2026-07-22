import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/presentation/vault_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vault_actions.g.dart';

/// The vault mutation façade (the interaction audit's CLASS 1 lock):
/// every session save/delete routes through here, and ONLY here —
/// `ref.invalidate` on vault surfaces outside this façade is banned.
///
/// DECLARED invalidation fan-out — save/delete ⇒
///   · [vaultViewModelProvider] (C7 list),
///   · [profileViewModelProvider] (C9 header's MI-11 freshness ring —
///     D16: the ring must re-derive after every capture/delete).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// keepAlive for the ratified orchestration reason: a read-only
/// controller must not unmount its Ref across the repository await.
@Riverpod(keepAlive: true)
class VaultActions extends _$VaultActions {
  @override
  void build() {}

  /// C6 results "Save to vault" — persists the pending capture session.
  Future<MeasurementSession> saveSession(String sessionId) async {
    final session = await ref
        .read(measurementRepositoryProvider)
        .saveSession(sessionId);
    _fanOut();
    return session;
  }

  /// MI-13 manual-entry save.
  Future<MeasurementSession> saveManualEntry(
    Map<String, double> valuesCm,
  ) async {
    final session = await ref
        .read(measurementRepositoryProvider)
        .saveManualEntry(valuesCm);
    _fanOut();
    return session;
  }

  /// The C7 history sheet's per-session delete.
  Future<void> deleteSession(String sessionId) async {
    await ref.read(measurementRepositoryProvider).deleteSession(sessionId);
    _fanOut();
  }

  void _fanOut() {
    ref
      ..invalidate(vaultViewModelProvider)
      ..invalidate(profileViewModelProvider);
  }
}
