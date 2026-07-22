/// A capture rejected by QC (capture-qc.md §1–2): [code] is the wire fail
/// code from the `422 {error: {code, message, guidance}}` envelope
/// (flows/vault.md §1) — the FIRST failing check in table order, never a
/// list. Presentation maps it 1:1 onto `QcFailCode` for the QCHintChip's
/// canonical guidance copy.
class CaptureQcException implements Exception {
  const CaptureQcException(this.code);

  /// Wire fail code, e.g. `not_frontal`.
  final String code;

  @override
  String toString() => 'CaptureQcException($code)';
}
