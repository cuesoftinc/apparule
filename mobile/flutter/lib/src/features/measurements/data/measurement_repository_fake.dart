import 'dart:convert';

import 'package:apparule/src/core/data/fail_next_seam.dart';
import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:apparule/src/features/measurements/data/capture_qc.dart';
import 'package:apparule/src/features/measurements/data/capture_sample_catalog.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:apparule/src/features/measurements/domain/measurement_exception.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Seed-backed fake (mobile-implementation.md §6/§10): the vault reads
/// `assets/seed/dev/vault_sessions.json` (the web mock seed's sessions,
/// shape-identical), and the capture flow implements capture-qc.md
/// HONESTLY — each submitted photo's sample scenario resolves to
/// simulated pipeline metrics, the real §1/§2 threshold tables run over
/// them in order **per pose** (front table first, side deltas second;
/// first-failure-only within the failing pose, M-10), passing captures
/// get the §3 `mediapipe_2d_v2` height-scale and §4 confidence formula.
/// No verdict or value is hardcoded per scenario.
class MeasurementRepositoryFake
    with FailNextSeam
    implements MeasurementRepository {
  MeasurementRepositoryFake({
    AssetBundle? bundle,
    DateTime Function()? now,
    this.processingDelay = const Duration(milliseconds: 600),
  }) : // An instance-scoped bundle, never the global rootBundle: its
       // string cache pins futures to the zone that first loaded them,
       // which deadlocks every later widget test (each testWidgets runs
       // its own FakeAsync zone). The fake is keepAlive, so the app
       // still parses each seed once.
       _bundle = bundle ?? PlatformAssetBundle(),
       _now = now ?? DateTime.now;

  static const String _vaultSeedAsset = 'assets/seed/dev/vault_sessions.json';

  final AssetBundle _bundle;
  final DateTime Function() _now;

  /// Simulated pipeline latency — long enough for the MI-12 processing
  /// constellation to read as a state, short enough for tests to pump.
  final Duration processingDelay;

  List<MeasurementSession>? _vault;
  final Map<String, MeasurementSession> _pending =
      <String, MeasurementSession>{};
  CaptureSampleCatalog? _catalog;
  int _localSequence = 0;

  Future<List<MeasurementSession>> _ensureVault() async {
    if (_vault case final vault?) return vault;
    List<MeasurementSession> seeded;
    try {
      final raw = await _bundle.loadString(_vaultSeedAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      seeded = <MeasurementSession>[
        for (final entry in json['sessions'] as List<dynamic>)
          _sessionFromSeed(entry as Map<String, dynamic>),
      ];
      // A missing asset surfaces as FlutterError (an Error subclass) —
      // the one Error this fake legitimately absorbs: §6 seeds are
      // dev-flavor-scoped, so a prod bundle (fakes, no seeds — the
      // pre-API interim) degrades to an empty vault instead of crashing.
      // ignore: avoid_catching_errors
    } on FlutterError {
      seeded = <MeasurementSession>[];
    }
    return _vault = seeded;
  }

  MeasurementSession _sessionFromSeed(Map<String, dynamic> json) {
    // Freshness narrative parity: the web seed computes daysAgo() at load
    // (never static dates that age out of their states) — so does this.
    final daysAgo = (json['created_days_ago'] as num).toInt();
    return MeasurementSession(
      id: json['id'] as String,
      method: json['method'] as String,
      status: SessionStatus.fromWireName(json['status'] as String),
      inputHeightCm: (json['input_height_cm'] as num?)?.toDouble(),
      createdAt: _now().subtract(Duration(days: daysAgo)),
      measurements: <Measurement>[
        for (final row in json['measurements'] as List<dynamic>)
          Measurement(
            id: (row as Map<String, dynamic>)['id'] as String,
            name: row['name'] as String,
            valueCm: (row['value_cm'] as num).toDouble(),
            confidence: (row['confidence'] as num?)?.toDouble(),
            source: row['source'] as String? ?? 'pipeline',
          ),
      ],
    );
  }

  Future<CaptureSampleCatalog> _ensureCatalog() async {
    if (_catalog case final catalog?) return catalog;
    try {
      return _catalog = await CaptureSampleCatalog.load(bundle: _bundle);
      // Missing-asset FlutterError, as in _ensureVault: no dev seed in
      // the bundle (prod flavor) → every capture evaluates as the
      // passing defaults.
      // ignore: avoid_catching_errors
    } on FlutterError {
      return _catalog = const CaptureSampleCatalog(
        imageAsset: '',
        samples: <CaptureSample>[],
      );
    }
  }

  @override
  Future<List<MeasurementSession>> vaultSessions() async {
    final vault = await _ensureVault();
    return List<MeasurementSession>.unmodifiable(
      vault.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<double?> lastInputHeightCm() async {
    final sessions = await vaultSessions();
    for (final session in sessions) {
      if (session.inputHeightCm case final height?) return height;
    }
    return null;
  }

  @override
  Future<MeasurementSession> submitCapture({
    required CapturePhoto front,
    required CapturePhoto side,
    required double userHeightCm,
  }) async {
    maybeFailNext();
    await _ensureVault();
    final catalog = await _ensureCatalog();
    await Future<void>.delayed(processingDelay);

    // Per-pose QC (capture-qc.md §2, M-10): the front table runs first,
    // then the side deltas — each pose reports its OWN first failure,
    // and a side failure leaves the accepted front frame undisturbed
    // (the client resubmits the same `front` with a fresh `side`).
    final metrics = catalog.metricsFor(front.sampleId);
    if (firstQcFailure(metrics) case final code?) {
      throw CaptureQcException(code, pose: CapturePose.front);
    }
    final sideMetrics = catalog.metricsFor(
      side.sampleId,
      pose: CapturePose.side,
    );
    if (firstQcFailure(sideMetrics, pose: CapturePose.side) case final code?) {
      throw CaptureQcException(code, pose: CapturePose.side);
    }

    // The front image alone owns the height scale (capture-qc.md §3 —
    // the nose→ankle axis is most stable in the frontal view); two-view
    // girth estimation lands with the backend recalibration directive.
    final scale = scaleFactor(userHeightCm, metrics.bodyHeightPx);
    double confidenceFor(String name) => measurementConfidence(
      // Landmarks a sample doesn't score default to a solid-visibility
      // 0.9 rather than silently passing 1.0.
      meanVisibility: metrics.landmarkVisibility[name] ?? 0.9,
      shoulderHipRatio: metrics.shoulderHipRatio,
      laplacianVariance: metrics.laplacianVariance,
    );

    final id = 'sess-local-${++_localSequence}';
    final session = MeasurementSession(
      id: id,
      method: 'mediapipe_2d_v2',
      status: SessionStatus.pendingSave,
      inputHeightCm: userHeightCm,
      createdAt: _now(),
      measurements: <Measurement>[
        Measurement(
          id: '$id-shoulder_width',
          name: 'shoulder_width',
          valueCm: metrics.shoulderWidthPx * scale,
          confidence: confidenceFor('shoulder_width'),
        ),
        Measurement(
          id: '$id-hip_width',
          name: 'hip_width',
          valueCm: metrics.hipWidthPx * scale,
          confidence: confidenceFor('hip_width'),
        ),
      ],
    );
    _pending[id] = session;
    return session;
  }

  @override
  Future<MeasurementSession> saveSession(String sessionId) async {
    maybeFailNext();
    final vault = await _ensureVault();
    final pending = _pending.remove(sessionId);
    if (pending == null) {
      throw StateError('No pending session $sessionId to save');
    }
    final saved = pending.copyWith(status: SessionStatus.complete);
    vault.insert(0, saved);
    return saved;
  }

  @override
  Future<void> discardSession(String sessionId) async {
    maybeFailNext();
    _pending.remove(sessionId);
  }

  @override
  Future<MeasurementSession> saveManualEntry(
    Map<String, double> valuesCm,
  ) async {
    maybeFailNext();
    final vault = await _ensureVault();
    final id = 'sess-local-${++_localSequence}';
    final session = MeasurementSession(
      id: id,
      method: 'manual',
      status: SessionStatus.complete,
      createdAt: _now(),
      measurements: <Measurement>[
        for (final MapEntry(key: name, value: valueCm) in valuesCm.entries)
          Measurement(
            id: '$id-$name',
            name: name,
            valueCm: valueCm,
            // capture-qc.md §4: manual rows are never scored.
          ),
      ],
    );
    vault.insert(0, session);
    return session;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    maybeFailNext();
    final vault = await _ensureVault();
    vault.removeWhere((session) => session.id == sessionId);
  }

  @override
  Future<String> exportSessionCsv(String sessionId) async {
    maybeFailNext();
    final vault = await _ensureVault();
    final session = vault.firstWhere(
      (session) => session.id == sessionId,
      orElse: () => throw StateError('No session $sessionId to export'),
    );
    // The F2-9 export shape: one row per measurement, confidence blank
    // for manual rows (capture-qc.md §4 — human truth isn't scored).
    final buffer = StringBuffer(
      'name,value_cm,confidence,method,measured_at\n',
    );
    for (final measurement in session.measurements) {
      final confidence = measurement.confidence?.toStringAsFixed(2) ?? '';
      buffer.writeln(
        '${measurement.name},${measurement.valueCm.toStringAsFixed(1)},'
        '$confidence,${session.method},'
        '${session.createdAt.toIso8601String()}',
      );
    }
    return buffer.toString();
  }
}
