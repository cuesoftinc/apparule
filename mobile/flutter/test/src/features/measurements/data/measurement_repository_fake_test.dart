import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:apparule/src/features/measurements/data/capture_sample_catalog.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:apparule/src/features/measurements/domain/measurement_exception.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The C6 session flow over the honest fake (mobile-implementation.md
/// §6/§10): seeded vault parity, submit → pending → save/discard, every
/// capture-qc.md fail code reproduced BY RULE from its sample scenario,
/// and the §3/§4 numbers on the happy path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedNow = DateTime.utc(2026, 7, 22, 12);
  MeasurementRepositoryFake repository() => MeasurementRepositoryFake(
    now: () => fixedNow,
    processingDelay: Duration.zero,
  );

  CapturePhoto photo(String sampleId) =>
      CapturePhoto(bytes: Uint8List(0), sampleId: sampleId);

  group('seeded vault (web mock parity)', () {
    test('lists the three seeded sessions newest first', () async {
      final sessions = await repository().vaultSessions();

      expect(sessions.map((s) => s.id).toList(), <String>[
        'sess-recent-scan',
        'sess-manual-tape',
        'sess-old-scan',
      ]);
      expect(sessions.first.method, 'mediapipe_2d_v2');
      expect(
        sessions.first.createdAt,
        fixedNow.subtract(const Duration(days: 12)),
      );
      expect(sessions[1].isManual, isTrue);
    });

    test('seeded values and confidences carry the web numbers', () async {
      final recent = (await repository().vaultSessions()).first;

      final shoulder = recent.measurements.first;
      expect(shoulder.name, 'shoulder_width');
      expect(shoulder.valueCm, 42.5);
      expect(shoulder.confidence, 0.92);
      final hip = recent.measurements[1];
      expect(hip.confidence, 0.62);
    });

    test('manual seed rows carry null confidence (§4: never scored)', () async {
      final sessions = await repository().vaultSessions();
      final manual = sessions.firstWhere((s) => s.isManual);

      expect(manual.measurements, hasLength(4));
      expect(
        manual.measurements.map((m) => m.confidence),
        everyElement(isNull),
      );
    });

    test('lastInputHeightCm reads the newest session', () async {
      expect(await repository().lastInputHeightCm(), 168);
    });
  });

  group('capture session flow (submit → pending → save | discard)', () {
    test('a passing frame resolves a pending mediapipe_2d_v2 session with '
        'the §3-scaled values and §4 confidences', () async {
      final repo = repository();

      final session = await repo.submitCapture(
        photo: photo('pass_frontal'),
        userHeightCm: 168,
      );

      expect(session.status, SessionStatus.pendingSave);
      expect(session.method, 'mediapipe_2d_v2');
      expect(session.inputHeightCm, 168);
      // scale = (168 × 0.93) / 1100; shoulder 300px, hip 250px.
      final shoulder = session.measurements.first;
      expect(shoulder.name, 'shoulder_width');
      expect(shoulder.valueCm, closeTo(42.61, 0.01));
      expect(shoulder.confidence, closeTo(0.92, 1e-9));
      final hip = session.measurements[1];
      expect(hip.name, 'hip_width');
      expect(hip.valueCm, closeTo(35.51, 0.01));
      expect(hip.confidence, closeTo(0.62, 1e-9));
    });

    test('the entered height drives the scale — same frame, taller claim, '
        'proportionally larger centimetres', () async {
      final repo = repository();

      final at168 = await repo.submitCapture(
        photo: photo('pass_frontal'),
        userHeightCm: 168,
      );
      final at190 = await repo.submitCapture(
        photo: photo('pass_frontal'),
        userHeightCm: 190,
      );

      expect(
        at190.measurements.first.valueCm / at168.measurements.first.valueCm,
        closeTo(190 / 168, 1e-9),
      );
    });

    test('pending sessions are not vault rows until saved', () async {
      final repo = repository();

      final pending = await repo.submitCapture(
        photo: photo('pass_frontal'),
        userHeightCm: 168,
      );
      expect(
        (await repo.vaultSessions()).map((s) => s.id),
        isNot(contains(pending.id)),
      );

      final saved = await repo.saveSession(pending.id);
      expect(saved.status, SessionStatus.complete);
      final vault = await repo.vaultSessions();
      expect(vault.first.id, pending.id);
      expect(vault, hasLength(4));
    });

    test(
      'discard purges immediately — a discarded session cannot save',
      () async {
        final repo = repository();

        final pending = await repo.submitCapture(
          photo: photo('pass_frontal'),
          userHeightCm: 168,
        );
        await repo.discardSession(pending.id);

        expect(await repo.vaultSessions(), hasLength(3));
        expect(() => repo.saveSession(pending.id), throwsStateError);
      },
    );

    test('a photo without a sample id (live camera) evaluates as the '
        'passing defaults', () async {
      final session = await repository().submitCapture(
        photo: CapturePhoto(bytes: Uint8List(0)),
        userHeightCm: 168,
      );
      expect(session.status, SessionStatus.pendingSave);
    });
  });

  group('QC fail codes — every capture-qc.md code, reproduced by rule', () {
    // One scenario per fail code (capture_samples.json); the repository
    // runs the REAL threshold table, so each expectation exercises the
    // documented rule, not a canned verdict.
    const expectedByScenario = <String, String>{
      'qc_undecodable_image': 'undecodable_image',
      'qc_low_resolution': 'low_resolution',
      'qc_poor_lighting': 'poor_lighting',
      'qc_blurry': 'blurry',
      'qc_no_body': 'no_body',
      'qc_multiple_bodies': 'multiple_bodies',
      'qc_partial_body': 'partial_body',
      'qc_not_frontal': 'not_frontal',
      'qc_camera_tilt': 'camera_tilt',
      'qc_arms_position': 'arms_position',
      'qc_too_far': 'too_far',
    };

    for (final MapEntry(key: scenario, value: code)
        in expectedByScenario.entries) {
      test('$scenario → $code', () async {
        await expectLater(
          repository().submitCapture(
            photo: photo(scenario),
            userHeightCm: 168,
          ),
          throwsA(
            isA<CaptureQcException>().having((e) => e.code, 'code', code),
          ),
        );
      });
    }

    test(
      'the multi-fault scenario reports its first table failure only',
      () async {
        await expectLater(
          repository().submitCapture(
            photo: photo('multi_fault'),
            userHeightCm: 168,
          ),
          throwsA(
            isA<CaptureQcException>().having(
              (e) => e.code,
              'code',
              'poor_lighting',
            ),
          ),
        );
      },
    );

    test('the QCHintChip enum maps every catalog fail code 1:1', () async {
      final catalog = await CaptureSampleCatalog.load();
      final failScenarios = catalog.samples.where(
        (s) => s.id.startsWith('qc_'),
      );

      expect(failScenarios, hasLength(11));
      for (final scenario in failScenarios) {
        final wire = scenario.id.substring('qc_'.length);
        expect(
          QcFailCode.fromWireName(wire),
          isNotNull,
          reason: '$wire must carry QCHintChip guidance copy',
        );
      }
      // And the enum carries nothing the contract doesn't: 11 codes.
      expect(QcFailCode.values, hasLength(11));
    });
  });

  group('manual entry (MI-13)', () {
    test('saves a manual session straight into the vault, unscored', () async {
      final repo = repository();

      final session = await repo.saveManualEntry(<String, double>{
        'shoulder_width': 43,
        'chest_girth': 91.5,
      });

      expect(session.isManual, isTrue);
      expect(session.status, SessionStatus.complete);
      expect(session.inputHeightCm, isNull);
      expect(
        session.measurements.map((m) => m.confidence),
        everyElement(isNull),
      );
      expect((await repo.vaultSessions()).first.id, session.id);
    });
  });

  group('prod degradation (no dev seeds in the bundle)', () {
    test('a bundle without seed assets yields an empty vault and passing '
        'captures', () async {
      final repo = MeasurementRepositoryFake(
        bundle: _EmptyAssetBundle(),
        processingDelay: Duration.zero,
      );

      expect(await repo.vaultSessions(), isEmpty);
      final session = await repo.submitCapture(
        photo: photo('qc_no_body'), // no catalog → passing defaults
        userHeightCm: 168,
      );
      expect(session.status, SessionStatus.pendingSave);
    });
  });

  test('failNext arms a throw-once failure on the next mutation '
      '(CLASS 4 seam)', () async {
    final repo = repository()..failNext = Exception('server 500');

    await expectLater(
      repo.deleteSession('sess-scan-fresh'),
      throwsException,
    );

    // Disarmed: the vault still holds three sessions and the retry lands.
    expect(await repo.vaultSessions(), hasLength(3));
    await repo.deleteSession((await repo.vaultSessions()).first.id);
    expect(await repo.vaultSessions(), hasLength(2));
  });
}

/// Simulates a prod bundle: every seed lookup is a missing asset.
class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
