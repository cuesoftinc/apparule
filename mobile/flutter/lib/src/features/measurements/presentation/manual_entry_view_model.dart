import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/presentation/vault_view_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manual_entry_view_model.freezed.dart';
part 'manual_entry_view_model.g.dart';

/// One manual measure with its advisory sanity range in cm — the client
/// twin of the server-side per-measure table (flows/vault.md §2:
/// out-of-range prompts a double-check, never a hard block).
typedef ManualMeasureSpec = ({String name, double min, double max});

/// The v1 manual vocabulary — the measures the seed narrative and the
/// request snapshot flow already speak (web seed parity); the open
/// vocabulary grows server-side.
const List<ManualMeasureSpec> kManualMeasures = <ManualMeasureSpec>[
  (name: 'shoulder_width', min: 25, max: 75),
  (name: 'hip_width', min: 20, max: 70),
  (name: 'chest_girth', min: 50, max: 160),
  (name: 'waist_girth', min: 40, max: 150),
];

@freezed
abstract class ManualEntryState with _$ManualEntryState {
  const factory ManualEntryState({
    /// Entered values, canonical cm (MI-13: unit is display-only).
    @Default(<String, double>{}) Map<String, double> valuesCm,
    @Default(MeasureUnit.cm) MeasureUnit unit,
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

  Future<void> save() async {
    if (state.valuesCm.isEmpty || state.saving) return;
    state = state.copyWith(saving: true);
    await ref
        .read(measurementRepositoryProvider)
        .saveManualEntry(state.valuesCm);
    ref.invalidate(vaultViewModelProvider);
    if (!ref.mounted) return;
    state = state.copyWith(saving: false, saved: true);
  }
}
