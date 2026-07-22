// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_save_flag.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the MI-3 first-save toast has ever shown (design.md §4:
/// "first-ever save shows 'Saved to your looks' toast with link" — once
/// per install, mirroring web's `first-save.ts` localStorage gate).
/// Saved state itself lives in the post repository; this only gates the
/// one-time toast.

@ProviderFor(FirstSaveFlag)
final firstSaveFlagProvider = FirstSaveFlagProvider._();

/// Whether the MI-3 first-save toast has ever shown (design.md §4:
/// "first-ever save shows 'Saved to your looks' toast with link" — once
/// per install, mirroring web's `first-save.ts` localStorage gate).
/// Saved state itself lives in the post repository; this only gates the
/// one-time toast.
final class FirstSaveFlagProvider
    extends $AsyncNotifierProvider<FirstSaveFlag, bool> {
  /// Whether the MI-3 first-save toast has ever shown (design.md §4:
  /// "first-ever save shows 'Saved to your looks' toast with link" — once
  /// per install, mirroring web's `first-save.ts` localStorage gate).
  /// Saved state itself lives in the post repository; this only gates the
  /// one-time toast.
  FirstSaveFlagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstSaveFlagProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstSaveFlagHash();

  @$internal
  @override
  FirstSaveFlag create() => FirstSaveFlag();
}

String _$firstSaveFlagHash() => r'cac6691b17b418c0ffd47ce068790c0889675650';

/// Whether the MI-3 first-save toast has ever shown (design.md §4:
/// "first-ever save shows 'Saved to your looks' toast with link" — once
/// per install, mirroring web's `first-save.ts` localStorage gate).
/// Saved state itself lives in the post repository; this only gates the
/// one-time toast.

abstract class _$FirstSaveFlag extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
