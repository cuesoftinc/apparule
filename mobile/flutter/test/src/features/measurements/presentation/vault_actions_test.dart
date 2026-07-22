import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/measurements/presentation/vault_actions.dart';
import 'package:apparule/src/features/measurements/presentation/vault_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_persistence.dart';

/// VaultActions two-surface contract (CLASS 1 lock, D16): one vault
/// mutation re-derives BOTH the C7 list and the C9 profile (whose MI-11
/// freshness ring hangs off the newest session).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    container = ProviderContainer(
      overrides: fakeRepositoryOverrides(
        persistenceService: InMemoryPersistenceService(),
        measurementRepository: MeasurementRepositoryFake(
          now: () => DateTime.utc(2026, 7, 22, 12),
          processingDelay: Duration.zero,
        ),
      ),
    );
    addTearDown(container.dispose);

    container
      ..listen(vaultViewModelProvider, (previous, next) {})
      ..listen(profileViewModelProvider, (previous, next) {});

    await container.read(vaultViewModelProvider.future);
    await container.read(profileViewModelProvider.future);
  });

  test('saveManualEntry re-derives vault AND profile ring', () async {
    final before = await container.read(vaultViewModelProvider.future);

    await container.read(vaultActionsProvider.notifier).saveManualEntry(
      <String, double>{'chest': 96, 'waist': 78},
    );

    final vault = await container.read(vaultViewModelProvider.future);
    final profile = await container.read(profileViewModelProvider.future);
    expect(vault, hasLength(before.length + 1));
    expect(profile?.vaultFreshness, 'fresh');
  });

  test('deleting every session empties the vault and clears the C9 ring '
      '(D16: the ring re-derives on delete too)', () async {
    final sessions = await container.read(vaultViewModelProvider.future);
    final actions = container.read(vaultActionsProvider.notifier);
    for (final session in sessions) {
      await actions.deleteSession(session.id);
    }

    final vault = await container.read(vaultViewModelProvider.future);
    final profile = await container.read(profileViewModelProvider.future);
    expect(vault, isEmpty);
    // No sessions → no freshness ladder value; the ring falls back to
    // the empty-vault affordance.
    expect(profile?.vaultFreshness, isNull);
  });
}
