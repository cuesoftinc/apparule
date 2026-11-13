import 'dart:convert';
import 'dart:typed_data';

import 'package:apparule/src/core/data/fail_next_seam.dart';
import 'package:apparule/src/core/utils/capture_pose.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/measurements/data/capture_qc.dart';
import 'package:apparule/src/features/measurements/data/capture_sample_catalog.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/capture_photo.dart';
import 'package:apparule/src/features/measurements/domain/measurement_exception.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/domain/measurement_share.dart';
import 'package:apparule/src/features/measurements/domain/measurement_template.dart';
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

/// Recalibrated-scan mock output (A-10b, web `SCAN_RESULTS_CM` parity):
/// deterministic reference cm at the 168 cm height, one <0.7 confidence
/// row per template.
const Map<
  MeasurementTemplate,
  List<({String name, double cm, double confidence})>
>
kScanResultsCm =
    <MeasurementTemplate, List<({String name, double cm, double confidence})>>{
      MeasurementTemplate.women: [
        (name: 'shoulder', cm: 42.7, confidence: 0.93),
        (name: 'bust', cm: 96.8, confidence: 0.9),
        (name: 'under_bust', cm: 86.2, confidence: 0.88),
        (name: 'bust_span', cm: 17.6, confidence: 0.84),
        (name: 'waist', cm: 78.1, confidence: 0.68),
        (name: 'shoulder_to_bust_point', cm: 26.1, confidence: 0.86),
        (name: 'shoulder_to_under_bust', cm: 34.6, confidence: 0.85),
        (name: 'shoulder_to_waist', cm: 41.2, confidence: 0.9),
        (name: 'half_length', cm: 46.2, confidence: 0.83),
        (name: 'waist_to_knee', cm: 53.2, confidence: 0.87),
        (name: 'gown_length', cm: 123.9, confidence: 0.9),
        (name: 'skirt_length', cm: 71.8, confidence: 0.82),
        (name: 'trouser_length', cm: 99.8, confidence: 0.88),
        (name: 'thigh', cm: 66.3, confidence: 0.8),
        (name: 'knee', cm: 40.7, confidence: 0.81),
        (name: 'sleeve_length', cm: 37.7, confidence: 0.89),
        (name: 'sleeve_width', cm: 34.2, confidence: 0.86),
      ],
      MeasurementTemplate.men: [
        (name: 'shoulder', cm: 47.0, confidence: 0.93),
        (name: 'chest', cm: 101.5, confidence: 0.9),
        (name: 'waist', cm: 86.5, confidence: 0.68),
        (name: 'top_length', cm: 73.5, confidence: 0.88),
        (name: 'thigh', cm: 58.5, confidence: 0.8),
        (name: 'hip', cm: 100.0, confidence: 0.9),
        (name: 'knee', cm: 39.0, confidence: 0.81),
        (name: 'shin', cm: 38.0, confidence: 0.79),
        (name: 'waist_to_knee', cm: 57.0, confidence: 0.87),
        (name: 'trouser_length', cm: 104.0, confidence: 0.88),
        (name: 'trouser_inseam', cm: 78.5, confidence: 0.86),
        (name: 'biceps', cm: 33.5, confidence: 0.84),
        (name: 'sleeve_length', cm: 62.0, confidence: 0.89),
        (name: 'neck', cm: 39.5, confidence: 0.9),
      ],
    };

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
    required MeasurementTemplate template,
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

    // A-10b: a scan maps the customer's FULL template (web mock parity —
    // deterministic reference cm at 168, scaled by the entered height;
    // exactly one row per template scores <0.7 so the low-confidence UI
    // stays exercised). The px metrics above still drive QC; per-field
    // value estimation lands with the backend recalibration.
    final heightScale = userHeightCm / 168;

    final id = 'sess-local-${++_localSequence}';
    final session = MeasurementSession(
      id: id,
      method: 'mediapipe_2d_v2',
      status: SessionStatus.pendingSave,
      inputHeightCm: userHeightCm,
      createdAt: _now(),
      measurements: <Measurement>[
        for (final (:name, :cm, :confidence) in kScanResultsCm[template]!)
          Measurement(
            id: '$id-$name',
            name: name,
            valueCm: ((cm * heightScale) * 10).roundToDouble() / 10,
            confidence: confidence,
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
    // Tailor-ready CSV: humanized measurement name, inches, and centimetres.
    final buffer = StringBuffer('Measurement,Inches,Centimetres\n');
    for (final measurement in session.measurements) {
      final label = humanizeMeasureName(measurement.name);
      final inches = (measurement.valueCm / cmPerInch).toStringAsFixed(1);
      final cm = measurement.valueCm.toStringAsFixed(1);
      buffer.writeln('$label,$inches in,$cm cm');
    }
    return buffer.toString();
  }

  @override
  Future<Uint8List> exportSessionPdf(String sessionId) async {
    maybeFailNext();
    final vault = await _ensureVault();
    final session = vault.firstWhere(
      (session) => session.id == sessionId,
      orElse: () => throw StateError('No session $sessionId to export'),
    );
    const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final utc = session.createdAt.toUtc();
    final weekday = weekdays[utc.weekday - 1];
    final month = months[utc.month - 1];
    final dateStr = '$weekday $month ${utc.day} ${utc.year}';
    final lines = <String>[
      'Apparule - Body Measurements',
      'Date: $dateStr',
      '',
    ];
    for (final measurement in session.measurements) {
      final label = humanizeMeasureName(measurement.name);
      final inches = (measurement.valueCm / cmPerInch).toStringAsFixed(1);
      final cm = measurement.valueCm.toStringAsFixed(1);
      lines.add('$label: $inches in ($cm cm)');
    }
    lines.addAll(<String>['', kApparuleLink]);
    return minimalPdf(lines);
  }
}

/// A real (minimal) PDF for the F2-9 pdf export (api.md §2.2 / web mock parity):
/// Helvetica text lines, uncompressed streams, byte-accurate xref — enough that
/// any viewer opens it.
Uint8List minimalPdf(List<String> lines) {
  String escape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

  String winAnsi(String s) {
    final normalized = s
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('·', '-');
    final buffer = StringBuffer();
    for (final char in normalized.runes) {
      if (char < 256) {
        buffer.writeCharCode(char);
      }
    }
    return buffer.toString();
  }

  const perPage = 36;
  final chunks = <List<String>>[];
  final totalLines = lines.isEmpty ? 1 : lines.length;
  for (var i = 0; i < totalLines; i += perPage) {
    final end = (i + perPage < lines.length) ? i + perPage : lines.length;
    chunks.add(lines.isEmpty ? <String>[] : lines.sublist(i, end));
  }

  final kids = <String>[
    for (var i = 0; i < chunks.length; i++) '${4 + 2 * i} 0 R',
  ];

  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [${kids.join(' ')}] /Count ${chunks.length} >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];

  for (var i = 0; i < chunks.length; i++) {
    final chunk = chunks[i];
    final text = <String>[];
    for (var j = 0; j < chunk.length; j++) {
      final lineText = escape(winAnsi(chunk[j]));
      text.add('1 0 0 1 72 ${720 - j * 18} Tm ($lineText) Tj');
    }
    final stream = 'BT\n/F1 12 Tf\n${text.join('\n')}\nET';
    final streamBytes = utf8.encode(stream);
    objects
      ..add(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Resources << /Font << /F1 3 0 R >> >> /Contents ${5 + 2 * i} 0 R >>',
      )
      ..add('<< /Length ${streamBytes.length} >>\nstream\n$stream\nendstream');
  }

  final buffer = BytesBuilder()..add(utf8.encode('%PDF-1.4\n'));
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(buffer.length);
    buffer.add(utf8.encode('${i + 1} 0 obj\n${objects[i]}\nendobj\n'));
  }

  final xref = buffer.length;
  final xrefHeader = 'xref\n0 ${objects.length + 1}\n0000000000 65535 f \n';
  buffer.add(utf8.encode(xrefHeader));
  for (final off in offsets) {
    buffer.add(utf8.encode('${off.toString().padLeft(10, '0')} 00000 n \n'));
  }
  buffer.add(
    utf8.encode(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xref\n%%EOF',
    ),
  );

  return buffer.toBytes();
}
