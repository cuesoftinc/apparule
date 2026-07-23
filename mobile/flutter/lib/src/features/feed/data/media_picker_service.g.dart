// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_picker_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden per entrypoint (di.dart): fakes carry
/// `MediaPickerServiceFake`; prod swaps in `MediaPickerServiceLive`
/// (hardware/photo-library access is not env-gated the way `*Remote`
/// repositories are — the real picker ships now).

@ProviderFor(mediaPickerService)
final mediaPickerServiceProvider = MediaPickerServiceProvider._();

/// Overridden per entrypoint (di.dart): fakes carry
/// `MediaPickerServiceFake`; prod swaps in `MediaPickerServiceLive`
/// (hardware/photo-library access is not env-gated the way `*Remote`
/// repositories are — the real picker ships now).

final class MediaPickerServiceProvider
    extends
        $FunctionalProvider<
          MediaPickerService,
          MediaPickerService,
          MediaPickerService
        >
    with $Provider<MediaPickerService> {
  /// Overridden per entrypoint (di.dart): fakes carry
  /// `MediaPickerServiceFake`; prod swaps in `MediaPickerServiceLive`
  /// (hardware/photo-library access is not env-gated the way `*Remote`
  /// repositories are — the real picker ships now).
  MediaPickerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaPickerServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaPickerServiceHash();

  @$internal
  @override
  $ProviderElement<MediaPickerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MediaPickerService create(Ref ref) {
    return mediaPickerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaPickerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaPickerService>(value),
    );
  }
}

String _$mediaPickerServiceHash() =>
    r'06ecde11d5d0e115824509710bcdb47932ecbc3a';
