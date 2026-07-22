// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_guide_flag.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the C6 instructional guide has ever been completed
/// (mobile-implementation.md §10: guide first, "skippable after first
/// completion" — a persisted flag, not session state). The ➕ entry and
/// the vault's capture card branch on it; [markCompleted] flips it when
/// the guide's last page confirms.

@ProviderFor(CaptureGuideFlag)
final captureGuideFlagProvider = CaptureGuideFlagProvider._();

/// Whether the C6 instructional guide has ever been completed
/// (mobile-implementation.md §10: guide first, "skippable after first
/// completion" — a persisted flag, not session state). The ➕ entry and
/// the vault's capture card branch on it; [markCompleted] flips it when
/// the guide's last page confirms.
final class CaptureGuideFlagProvider
    extends $AsyncNotifierProvider<CaptureGuideFlag, bool> {
  /// Whether the C6 instructional guide has ever been completed
  /// (mobile-implementation.md §10: guide first, "skippable after first
  /// completion" — a persisted flag, not session state). The ➕ entry and
  /// the vault's capture card branch on it; [markCompleted] flips it when
  /// the guide's last page confirms.
  CaptureGuideFlagProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureGuideFlagProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureGuideFlagHash();

  @$internal
  @override
  CaptureGuideFlag create() => CaptureGuideFlag();
}

String _$captureGuideFlagHash() => r'ef6453611b3e7b5944fb2700a69e6bbde711cd53';

/// Whether the C6 instructional guide has ever been completed
/// (mobile-implementation.md §10: guide first, "skippable after first
/// completion" — a persisted flag, not session state). The ➕ entry and
/// the vault's capture card branch on it; [markCompleted] flips it when
/// the guide's last page confirms.

abstract class _$CaptureGuideFlag extends $AsyncNotifier<bool> {
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
