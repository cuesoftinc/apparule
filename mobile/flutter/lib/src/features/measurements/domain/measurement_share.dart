import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';

/// A-11 measurement share (decisions.md, ratified 2026-07-31) — the
/// WhatsApp-to-tailor flow, web parity with
/// `web/src/components/dashboard/vault/measurements-share.ts`.
const String kApparuleLink = 'https://apparule.cuesoft.io';

/// Latest value per metric, first-seen order across newest-first
/// sessions (template order after a scan).
List<Measurement> latestMeasurements(List<MeasurementSession> sessions) {
  final names = <String>[];
  final latest = <String, Measurement>{};
  for (final session in sessions) {
    for (final measurement in session.measurements) {
      if (!names.contains(measurement.name)) {
        names.add(measurement.name);
        latest[measurement.name] = measurement;
      }
    }
  }
  return <Measurement>[for (final name in names) latest[name]!];
}

/// "My measurements (Apparule)" + one humanized line per latest value in
/// the display unit (inches by default, A-9) + the product link.
String measurementsShareText(
  List<Measurement> latest, [
  MeasureUnit unit = MeasureUnit.inch,
]) {
  return <String>[
    'My measurements (Apparule)',
    for (final m in latest)
      '${humanizeMeasureName(m.name)}: ${formatCm(m.valueCm, unit)}',
    kApparuleLink,
  ].join('\n');
}
