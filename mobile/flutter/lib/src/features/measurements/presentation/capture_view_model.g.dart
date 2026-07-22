// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// C6's ViewModel (1:1 with `CaptureScreen`) — owns the capture session
/// flow; navigation stays the View's job.

@ProviderFor(CaptureViewModel)
final captureViewModelProvider = CaptureViewModelProvider._();

/// C6's ViewModel (1:1 with `CaptureScreen`) — owns the capture session
/// flow; navigation stays the View's job.
final class CaptureViewModelProvider
    extends $NotifierProvider<CaptureViewModel, CaptureState> {
  /// C6's ViewModel (1:1 with `CaptureScreen`) — owns the capture session
  /// flow; navigation stays the View's job.
  CaptureViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureViewModelHash();

  @$internal
  @override
  CaptureViewModel create() => CaptureViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaptureState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaptureState>(value),
    );
  }
}

String _$captureViewModelHash() => r'5e68c21a85c52ff5d07af8eb8bd1b9b7ddd44881';

/// C6's ViewModel (1:1 with `CaptureScreen`) — owns the capture session
/// flow; navigation stays the View's job.

abstract class _$CaptureViewModel extends $Notifier<CaptureState> {
  CaptureState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CaptureState, CaptureState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CaptureState, CaptureState>,
              CaptureState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
