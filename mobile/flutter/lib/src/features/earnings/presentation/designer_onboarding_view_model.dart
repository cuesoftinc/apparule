import 'package:apparule/src/features/earnings/data/earnings_repository.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_view_model.dart';
import 'package:apparule/src/features/profile/data/profile_repository.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'designer_onboarding_view_model.freezed.dart';
part 'designer_onboarding_view_model.g.dart';

/// The C13 intro form's prefill — the account's own identity seeds the
/// designer handle suggestion (canvas 204:1140 shows the username +
/// display-name fields pre-populated).
@freezed
abstract class OnboardingPrefill with _$OnboardingPrefill {
  const factory OnboardingPrefill({
    required String username,
    required String displayName,
  }) = _OnboardingPrefill;
}

/// C13 intro — create the designer profile, then hand off to the payout
/// form ("Post right away — add banking details when you're ready").
@riverpod
class DesignerOnboardingViewModel extends _$DesignerOnboardingViewModel {
  @override
  Future<OnboardingPrefill> build() async {
    final me = await ref.watch(profileRepositoryProvider).me();
    return OnboardingPrefill(
      username: me?.username ?? '',
      displayName: me?.displayName ?? '',
    );
  }

  Future<void> create({
    required String username,
    required String displayName,
    required String bio,
  }) async {
    await ref
        .read(earningsRepositoryProvider)
        .enableDesigner(
          username: username,
          displayName: displayName,
          bio: bio.trim().isEmpty ? null : bio,
        );
    // The designer side just opened — every surface that branches on it
    // re-derives (C9 grid tabs, settings rows, C14, the ➕ entry's
    // future role check).
    ref
      ..invalidate(designerStatusProvider)
      ..invalidate(earningsViewModelProvider)
      ..invalidate(profileViewModelProvider);
  }
}
