// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden per entrypoint (di.dart): fakes carry `CameraServiceFake`;
/// prod swaps in `CameraServiceLive` (hardware is not env-gated the way
/// `*Remote` repositories are — the real viewfinder ships now, the real
/// pipeline with the API wave).

@ProviderFor(cameraService)
final cameraServiceProvider = CameraServiceProvider._();

/// Overridden per entrypoint (di.dart): fakes carry `CameraServiceFake`;
/// prod swaps in `CameraServiceLive` (hardware is not env-gated the way
/// `*Remote` repositories are — the real viewfinder ships now, the real
/// pipeline with the API wave).

final class CameraServiceProvider
    extends $FunctionalProvider<CameraService, CameraService, CameraService>
    with $Provider<CameraService> {
  /// Overridden per entrypoint (di.dart): fakes carry `CameraServiceFake`;
  /// prod swaps in `CameraServiceLive` (hardware is not env-gated the way
  /// `*Remote` repositories are — the real viewfinder ships now, the real
  /// pipeline with the API wave).
  CameraServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraServiceHash();

  @$internal
  @override
  $ProviderElement<CameraService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CameraService create(Ref ref) {
    return cameraService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CameraService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CameraService>(value),
    );
  }
}

String _$cameraServiceHash() => r'cd1071539a9420c28f7e88a77bcb9f751951a355';
