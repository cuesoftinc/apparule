/// The C5 submit error surface the UI handles — flows/request.md §1
/// failure-taxonomy parity (web `ApiError.code`); transport/provider
/// details never cross the repository boundary.
enum OrderErrorCode {
  /// An open request already exists for this customer+post (web 409
  /// `duplicate_request`) — the error banner offers "View orders".
  duplicateRequest,

  /// The picked vault session vanished between steps (web 422
  /// `snapshot_invalid`).
  snapshotInvalid,

  /// Anything else — the generic "try again" banner.
  networkFailed,
}

/// Repository-boundary order failure carrying a UI-mappable [code]
/// (the `EarningsException` shape, carried to orders).
class OrderException implements Exception {
  const OrderException(this.code, [this.message]);

  final OrderErrorCode code;

  /// Underlying detail, for logs — never rendered verbatim.
  final String? message;

  @override
  String toString() =>
      'OrderException(${code.name}${message == null ? '' : ': $message'})';
}
