import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_session.freezed.dart';

/// Minimal placeholder domain model — the capture wave grows it to the
/// capture-qc.md §4 result shape (per-measurement confidence, QC codes).
@freezed
abstract class MeasurementSession with _$MeasurementSession {
  const factory MeasurementSession({required String id}) = _MeasurementSession;
}
