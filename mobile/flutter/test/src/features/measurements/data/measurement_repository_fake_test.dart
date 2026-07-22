import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:apparule/src/features/measurements/data/capture_sample_catalog.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:apparule/src/features/measurements/domain/measurement_exception.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The C6 session flow over the honest fake (mobile-implementation.md
/// §6/§10, M-10 two-pose): seeded vault parity, two-image submit →
/// pending → save/discard, every capture-qc.md fail code — BOTH poses'
/// tables — reproduced BY RULE from its sample scenario, per-pose
/// first-failure ordering, and the §3/§4 numbers on the happy path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedNow = DateTime.utc(2026, 7, 22, 12);
  MeasurementRepositoryFake repository() => MeasurementRepositoryFake(
    now: () => fixedNow,
    processingDelay: Duration.zero,
  );

  CapturePhoto photo(String sampleId) =>
      CapturePhoto(bytes: Uint8List(0), sampleId: sampleId);

  /// The two-image submit (api.md `POST /measure`: `image_front` +
  /// `image_side` + `user_height_cm`) with passing defaults per pose.
  Future<MeasurementSession> submit(
    MeasurementRepositoryFake repo, {
    String front = 'pass_frontal',
    String side = 'pass_side',
    double heightCm = 168,
  }) => repo.submitCapture(
    front: photo(front),
    side: photo(side),
    userHeightCm: heightCm,
  );

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
    test('a passing two-image capture resolves a pending mediapipe_2d_v2 '
        'session with the §3-scaled values and §4 confidences', () async {
      final repo = repository();

      final session = await submit(repo);

      expect(session.status, SessionStatus.pendingSave);
      expect(session.method, 'mediapipe_2d_v2');
      expect(session.inputHeightCm, 168);
      // scale = (168 × 0.93) / 1100 — the FRONT image owns the height
      // scale (capture-qc.md §3); shoulder 300px, hip 250px.
      final shoulder = session.measurements.first;
      expect(shoulder.name, 'shoulder_width');
      expect(shoulder.valueCm, closeTo(42.61, 0.01));
      expect(shoulder.confidence, closeTo(0.92, 1e-9));
      final hip = session.measurements[1];
      expect(hip.name, 'hip_width');
      expect(hip.valueCm, closeTo(35.51, 0.01));
      expect(hip.confidence, closeTo(0.62, 1e-9));
    });

    test('the entered height drives the scale — same frames, taller claim, '
        'proportionally larger centimetres', () async {
      final repo = repository();

      final at168 = await submit(repo);
      final at190 = await submit(repo, heightCm: 190);

      expect(
        at190.measurements.first.valueCm / at168.measurements.first.valueCm,
        closeTo(190 / 168, 1e-9),
      );
    });

    test('pending sessions are not vault rows until saved', () async {
      final repo = repository();

      final pending = await submit(repo);
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

        final pending = await submit(repo);
        await repo.discardSession(pending.id);

        expect(await repo.vaultSessions(), hasLength(3));
        expect(() => repo.saveSession(pending.id), throwsStateError);
      },
    );

    test(
      'photos without sample ids (live camera) evaluate as each '
      "pose's passing defaults — the side defaults describe a side-on "
      'subject, never the front-passing frame the side table rejects',
      () async {
        final session = await repository().submitCapture(
          front: CapturePhoto(bytes: Uint8List(0)),
          side: CapturePhoto(bytes: Uint8List(0)),
          userHeightCm: 168,
        );
        expect(session.status, SessionStatus.pendingSave);
      },
    );
  });

  group('per-pose QC — every capture-qc.md code, reproduced by rule', () {
    // One scenario per fail code (capture_samples.json); the repository
    // runs the REAL per-pose threshold tables, so each expectation
    // exercises the documented rule, not a canned verdict.
    const frontCodes = <String, String>{
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

    for (final MapEntry(key: scenario, value: code) in frontCodes.entries) {
      test('front $scenario → $code (pose: front)', () async {
        await expectLater(
          submit(repository(), front: scenario),
          throwsA(
            isA<CaptureQcException>()
                .having((e) => e.code, 'code', code)
                .having((e) => e.pose, 'pose', CapturePose.front),
          ),
        );
      });
    }

    // The side pose's table: the swapped rows (not_side_profile, the
    // arms-relaxed rule) plus shared pre-check/body rows on the side
    // frame.
    const sideCodes = <String, String>{
      'qc_not_side_profile': 'not_side_profile',
      'qc_side_arms_position': 'arms_position',
      'qc_side_poor_lighting': 'poor_lighting',
      'qc_side_blurry': 'blurry',
      'qc_side_too_far': 'too_far',
    };

    for (final MapEntry(key: scenario, value: code) in sideCodes.entries) {
      test('side $scenario → $code (pose: side)', () async {
        await expectLater(
          submit(repository(), side: scenario),
          throwsA(
            isA<CaptureQcException>()
                .having((e) => e.code, 'code', code)
                .having((e) => e.pose, 'pose', CapturePose.side),
          ),
        );
      });
    }

    test('a frontal subject on the side pose fails not_side_profile — the '
        'passing FRONT frame is exactly what the side table rejects', () async {
      await expectLater(
        submit(repository(), side: 'pass_frontal'),
        throwsA(
          isA<CaptureQcException>()
              .having((e) => e.code, 'code', 'not_side_profile')
              .having((e) => e.pose, 'pose', CapturePose.side),
        ),
      );
    });

    test('front table runs first: both poses failing reports the FRONT '
        'failure (per-pose reporting, front first)', () async {
      await expectLater(
        submit(
          repository(),
          front: 'qc_blurry',
          side: 'qc_not_side_profile',
        ),
        throwsA(
          isA<CaptureQcException>()
              .having((e) => e.code, 'code', 'blurry')
              .having((e) => e.pose, 'pose', CapturePose.front),
        ),
      );
    });

    test(
      'first-failure-only within the FRONT pose (multi-fault frame)',
      () async {
        await expectLater(
          submit(repository(), front: 'multi_fault'),
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

    test('first-failure-only within the SIDE pose (side multi-fault: '
        'orientation beats arms and scale in table order)', () async {
      await expectLater(
        submit(repository(), side: 'side_multi_fault'),
        throwsA(
          isA<CaptureQcException>()
              .having((e) => e.code, 'code', 'not_side_profile')
              .having((e) => e.pose, 'pose', CapturePose.side),
        ),
      );
    });

    test('a pose-2 failure leaves the accepted pose-1 frame undisturbed: '
        'resubmitting the SAME front with a fixed side passes', () async {
      final repo = repository();
      final front = photo('pass_frontal');

      await expectLater(
        repo.submitCapture(
          front: front,
          side: photo('qc_not_side_profile'),
          userHeightCm: 168,
        ),
        throwsA(isA<CaptureQcException>()),
      );

      // The client re-enters the SIDE camera only and resubmits the
      // accepted front frame untouched.
      final session = await repo.submitCapture(
        front: front,
        side: photo('pass_side'),
        userHeightCm: 168,
      );
      expect(session.status, SessionStatus.pendingSave);
    });

    test('the QCHintChip enum maps every catalog fail code 1:1', () async {
      final catalog = await CaptureSampleCatalog.load();
      final wires = <String>{...frontCodes.values, ...sideCodes.values};

      for (final wire in wires) {
        expect(
          QcFailCode.fromWireName(wire),
          isNotNull,
          reason: '$wire must carry QCHintChip guidance copy',
        );
      }
      // The catalog reaches every code the chip knows: 12 codes — the 11
      // front-era codes + not_side_profile (M-10).
      expect(QcFailCode.values, hasLength(12));
      // And every catalog scenario belongs to a pose group the dev
      // selector lists.
      expect(
        catalog.samplesFor(CapturePose.front).length +
            catalog.samplesFor(CapturePose.side).length,
        catalog.samples.length,
      );
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

  group('per-session export (F2-9)', () {
    test('renders the session CSV — one row per measurement, confidence '
        'blank on manual rows', () async {
      final repo = repository();

      final csv = await repo.exportSessionCsv('sess-manual-tape');

      final lines = csv.trim().split('\n');
      expect(lines.first, 'name,value_cm,confidence,method,measured_at');
      expect(lines, hasLength(5));
      expect(lines[1], startsWith('shoulder_width,'));
      expect(lines[1], contains(',,manual,'));
    });

    test('scan sessions carry their confidences', () async {
      final csv = await repository().exportSessionCsv('sess-recent-scan');
      expect(csv, contains('shoulder_width,42.5,0.92,mediapipe_2d_v2,'));
    });

    test('unknown session ids throw', () async {
      expect(
        () => repository().exportSessionCsv('sess-nope'),
        throwsStateError,
      );
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
        front: photo('qc_no_body'), // no catalog → passing defaults
        side: photo('qc_not_side_profile'),
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
