// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The UI clock — every screen-side "how long ago / how fresh" read goes
/// through this instead of a bare `DateTime.now()`, so golden scenarios
/// can pin one instant for BOTH the seeded fakes and the rendering pass
/// (relative labels and freshness ladders stay byte-stable).

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// The UI clock — every screen-side "how long ago / how fresh" read goes
/// through this instead of a bare `DateTime.now()`, so golden scenarios
/// can pin one instant for BOTH the seeded fakes and the rendering pass
/// (relative labels and freshness ladders stay byte-stable).

final class ClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// The UI clock — every screen-side "how long ago / how fresh" read goes
  /// through this instead of a bare `DateTime.now()`, so golden scenarios
  /// can pin one instant for BOTH the seeded fakes and the rendering pass
  /// (relative labels and freshness ladders stay byte-stable).
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$clockHash() => r'3f65ad34ac6fcd532de9004042bdf2ed2bd85b13';
