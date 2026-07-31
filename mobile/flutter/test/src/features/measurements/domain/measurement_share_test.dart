import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/domain/measurement_share.dart';
import 'package:flutter_test/flutter_test.dart';

Measurement _m(String name, double valueCm) => Measurement(
  id: 'm-$name',
  name: name,
  valueCm: valueCm,
  confidence: null,
  source: 'pipeline',
);

MeasurementSession _session(String id, List<Measurement> measurements) =>
    MeasurementSession(
      id: id,
      method: 'manual',
      status: SessionStatus.complete,
      inputHeightCm: null,
      createdAt: DateTime(2026, 7, 30),
      measurements: measurements,
    );

void main() {
  // A-11 share text (decisions.md) — web parity with
  // measurements-share.ts.
  test('renders header, humanized inch lines, and the link', () {
    final text = measurementsShareText(<Measurement>[
      _m('shoulder', 42.5),
      _m('shoulder_to_bust_point', 26),
    ]);
    expect(
      text,
      'My measurements (Apparule)\n'
      'Shoulder: 16.7 in\n'
      'Shoulder to bust point: 10.2 in\n'
      '$kApparuleLink',
    );
  });

  test('latestMeasurements folds newest-first sessions per metric', () {
    final latest = latestMeasurements(<MeasurementSession>[
      _session('new', <Measurement>[_m('shoulder', 42.5)]),
      _session('old', <Measurement>[_m('shoulder', 41.8), _m('waist', 77.4)]),
    ]);
    expect(latest.map((m) => '${m.name} ${m.valueCm}'), <String>[
      'shoulder 42.5',
      'waist 77.4',
    ]);
  });
}
