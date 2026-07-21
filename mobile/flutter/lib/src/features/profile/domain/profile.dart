import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// Minimal placeholder domain model — fields grow with the screens wave
/// (mobile-implementation.md §6 me/designers seeds).
@freezed
abstract class Profile with _$Profile {
  const factory Profile({required String username}) = _Profile;
}
