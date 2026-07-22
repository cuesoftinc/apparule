import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

/// The signed-in identity (mobile-implementation.md §9) — mapped from the
/// Firebase user (Google-asserted profile fields) or the seeded fake
/// persona. Its presence/absence on the session provider is what the
/// router's auth redirect keys off.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) = _AuthSession;
}
