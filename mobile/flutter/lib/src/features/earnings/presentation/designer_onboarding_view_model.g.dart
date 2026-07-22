// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'designer_onboarding_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C13 intro — create the designer profile, then hand off to the payout
/// form ("Post right away — add banking details when you're ready").

@ProviderFor(DesignerOnboardingViewModel)
final designerOnboardingViewModelProvider =
    DesignerOnboardingViewModelProvider._();

/// C13 intro — create the designer profile, then hand off to the payout
/// form ("Post right away — add banking details when you're ready").
final class DesignerOnboardingViewModelProvider
    extends
        $AsyncNotifierProvider<DesignerOnboardingViewModel, OnboardingPrefill> {
  /// C13 intro — create the designer profile, then hand off to the payout
  /// form ("Post right away — add banking details when you're ready").
  DesignerOnboardingViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'designerOnboardingViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$designerOnboardingViewModelHash();

  @$internal
  @override
  DesignerOnboardingViewModel create() => DesignerOnboardingViewModel();
}

String _$designerOnboardingViewModelHash() =>
    r'850b36469e2987cbfc2aa439ab6cb6096ba115b9';

/// C13 intro — create the designer profile, then hand off to the payout
/// form ("Post right away — add banking details when you're ready").

abstract class _$DesignerOnboardingViewModel
    extends $AsyncNotifier<OnboardingPrefill> {
  FutureOr<OnboardingPrefill> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OnboardingPrefill>, OnboardingPrefill>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingPrefill>, OnboardingPrefill>,
              AsyncValue<OnboardingPrefill>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
