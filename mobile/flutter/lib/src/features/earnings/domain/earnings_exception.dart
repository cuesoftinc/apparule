/// The earnings/KYC error surface the C13/C14 UI handles — mock-store
/// error-code parity (web `MockApiError.code`); provider SDK details
/// never cross the repository boundary.
enum EarningsErrorCode {
  /// Earnings/payout calls without a designer profile (web 403
  /// `designer_profile_required`) — C14 renders the become-a-designer
  /// empty state.
  designerProfileRequired,

  /// Paystack couldn't resolve the account (web 422
  /// `bank_resolution_failed`) — the C13 failed state with retry +
  /// support link.
  bankResolutionFailed,

  /// Missing/invalid form input (web 422 `validation_failed`).
  validationFailed,
}

/// Repository-boundary earnings failure carrying a UI-mappable [code].
class EarningsException implements Exception {
  const EarningsException(this.code, [this.message]);

  final EarningsErrorCode code;

  /// Underlying detail, for logs — never rendered verbatim.
  final String? message;

  @override
  String toString() =>
      'EarningsException(${code.name}${message == null ? '' : ': $message'})';
}
