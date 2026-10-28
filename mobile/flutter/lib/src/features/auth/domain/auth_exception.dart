/// The auth error surface the UI handles (flows/auth.md §4) — SDK-specific
/// exceptions (`PlatformException`, `DioException`) never
/// cross the repository boundary.
enum AuthErrorCode {
  /// Sheet/popup dismissed (or interrupted) — silent return, screen
  /// unchanged (flows/auth.md §4).
  canceled,

  /// Connection failure or timeout: offline notice + retry.
  network,

  /// Disabled account: "This account has been disabled".
  userDisabled,

  /// Anything else — generic retry copy; details carried for logging.
  unknown,
}

/// Repository-boundary auth failure carrying a UI-mappable [code].
class AuthException implements Exception {
  const AuthException(this.code, [this.message]);

  final AuthErrorCode code;

  /// Underlying SDK detail, for logs — never rendered verbatim.
  final String? message;

  @override
  String toString() =>
      'AuthException(${code.name}${message == null ? '' : ': $message'})';
}
