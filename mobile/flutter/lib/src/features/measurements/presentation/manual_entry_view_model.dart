import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/measurements/presentation/vault_actions.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manual_entry_view_model.freezed.dart';
part 'manual_entry_view_model.g.dart';

/// One manual measure with its advisory sanity range in cm — the client
/// twin of the server-side per-measure table (flows/vault.md §2:
/// out-of-range prompts a double-check, never a hard block).
typedef ManualMeasureSpec = ({String name, double min, double max});

/// The canonical A-10 tailor templates — flows/vault.md §2 [Decided
/// 2026-07-25: field list collected from a practicing Nigerian tailor].
/// The profile's `measurementTemplate` selects the set; the 7 measures
/// shared by both templates carry identical ranges. Legacy names on
/// historical sessions stay valid (open vocabulary; sessions immutable).
const Map<MeasurementTemplate, List<ManualMeasureSpec>> kManualTemplates =
    <MeasurementTemplate, List<ManualMeasureSpec>>{
      MeasurementTemplate.women: <ManualMeasureSpec>[
        (name: 'shoulder', min: 30, max: 60),
        (name: 'bust', min: 60, max: 160),
        (name: 'under_bust', min: 55, max: 140),
        (name: 'bust_span', min: 12, max: 30),
        (name: 'waist', min: 50, max: 150),
        (name: 'shoulder_to_bust_point', min: 18, max: 40),
        (name: 'shoulder_to_under_bust', min: 25, max: 50),
        (name: 'shoulder_to_waist', min: 30, max: 60),
        (name: 'half_length', min: 30, max: 70),
        (name: 'waist_to_knee', min: 40, max: 75),
        (name: 'gown_length', min: 90, max: 170),
        (name: 'skirt_length', min: 40, max: 120),
        (name: 'trouser_length', min: 80, max: 120),
        (name: 'thigh', min: 40, max: 90),
        (name: 'knee', min: 25, max: 60),
        (name: 'sleeve_length', min: 15, max: 70),
        (name: 'sleeve_width', min: 20, max: 50),
      ],
      MeasurementTemplate.men: <ManualMeasureSpec>[
        (name: 'shoulder', min: 30, max: 60),
        (name: 'chest', min: 70, max: 160),
        (name: 'waist', min: 50, max: 150),
        (name: 'top_length', min: 55, max: 100),
        (name: 'thigh', min: 40, max: 90),
        (name: 'hip', min: 70, max: 160),
        (name: 'knee', min: 25, max: 60),
        (name: 'shin', min: 20, max: 50),
        (name: 'waist_to_knee', min: 40, max: 75),
        (name: 'trouser_length', min: 80, max: 120),
        (name: 'trouser_inseam', min: 60, max: 95),
        (name: 'biceps', min: 20, max: 50),
        (name: 'sleeve_length', min: 15, max: 70),
        (name: 'neck', min: 25, max: 55),
      ],
    };

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
