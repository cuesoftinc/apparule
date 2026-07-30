import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/measurements/domain/measurement_template.dart';
import 'package:apparule/src/features/measurements/presentation/vault_actions.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:apparule/src/features/measurements/domain/measurement_template.dart';

part 'manual_entry_view_model.freezed.dart';
part 'manual_entry_view_model.g.dart';

/// The profile's A-10 template — null interposes the one-time chooser on
/// the manual entry screen. Auto-disposes with the route, so a Settings
/// edit is picked up on the next visit.
@riverpod
Future<MeasurementTemplate?> manualTemplate(Ref ref) async {
  final me = await ref.watch(profileRepositoryProvider).me();
  return me?.measurementTemplate;
}

@freezed
abstract class ManualEntryState with _$ManualEntryState {
  const factory ManualEntryState({
    /// Entered values, canonical cm (MI-13: unit is display-only,
    /// inches by default — A-9).
    @Default(<String, double>{}) Map<String, double> valuesCm,
    @Default(MeasureUnit.inch) MeasureUnit unit,
    @Default(false) bool saving,

    /// Save landed — the screen routes to the vault (C7).
    @Default(false) bool saved,
  }) = _ManualEntryState;
}

/// MI-13 manual entry (1:1 with `ManualEntryScreen`) — the C6 fallback
/// path for QC that never clears or a denied camera; saves a
/// `method: manual` session (confidence null, capture-qc.md §4).
@riverpod
class ManualEntryViewModel extends _$ManualEntryViewModel {
  @override
  ManualEntryState build() => const ManualEntryState();

  void setValue(String name, double? valueCm) {
    final values = Map<String, double>.of(state.valuesCm);
    if (valueCm == null) {
      values.remove(name);
    } else {
      values[name] = valueCm;
    }
    state = state.copyWith(valuesCm: values);
  }

  void setUnit(MeasureUnit unit) {
    state = state.copyWith(unit: unit);
  }

  /// A-10 one-time chooser pick — persists to the profile (the PATCH /me
  /// analogue) and refreshes [manualTemplate] so the rows swap in place.
  Future<void> pickTemplate(MeasurementTemplate template) async {
    if (state.saving) return;
    state = state.copyWith(saving: true);
    await ref.read(profileRepositoryProvider).setMeasurementTemplate(template);
    ref.invalidate(manualTemplateProvider);
    if (!ref.mounted) return;
    state = state.copyWith(saving: false);
  }

  /// Saves through the VaultActions façade (CLASS 1 lock) — its declared
  /// fan-out re-derives the C7 list AND the C9 header's MI-11 freshness
  /// ring (D16).
  Future<void> save() async {
    if (state.valuesCm.isEmpty || state.saving) return;
    state = state.copyWith(saving: true);
    await ref
        .read(vaultActionsProvider.notifier)
        .saveManualEntry(state.valuesCm);
    if (!ref.mounted) return;
    state = state.copyWith(saving: false, saved: true);
  }
}
