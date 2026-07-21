import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

/// Minimal placeholder domain model — fields grow at the auth cutover
/// (mobile-implementation.md §9).
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({required String uid}) = _AuthSession;
}
