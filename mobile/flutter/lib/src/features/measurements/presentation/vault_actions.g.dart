// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The vault mutation façade (the interaction audit's CLASS 1 lock):
/// every session save/delete routes through here, and ONLY here —
/// `ref.invalidate` on vault surfaces outside this façade is banned.
///
/// DECLARED invalidation fan-out — save/delete ⇒
///   · [vaultViewModelProvider] (C7 list),
///   · [profileViewModelProvider] (C9 header's MI-11 freshness ring —
///     D16: the ring must re-derive after every capture/delete).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// keepAlive for the ratified orchestration reason: a read-only
/// controller must not unmount its Ref across the repository await.

@ProviderFor(VaultActions)
final vaultActionsProvider = VaultActionsProvider._();

/// The vault mutation façade (the interaction audit's CLASS 1 lock):
/// every session save/delete routes through here, and ONLY here —
/// `ref.invalidate` on vault surfaces outside this façade is banned.
///
/// DECLARED invalidation fan-out — save/delete ⇒
///   · [vaultViewModelProvider] (C7 list),
///   · [profileViewModelProvider] (C9 header's MI-11 freshness ring —
///     D16: the ring must re-derive after every capture/delete).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// keepAlive for the ratified orchestration reason: a read-only
/// controller must not unmount its Ref across the repository await.
final class VaultActionsProvider extends $NotifierProvider<VaultActions, void> {
  /// The vault mutation façade (the interaction audit's CLASS 1 lock):
  /// every session save/delete routes through here, and ONLY here —
  /// `ref.invalidate` on vault surfaces outside this façade is banned.
  ///
  /// DECLARED invalidation fan-out — save/delete ⇒
  ///   · [vaultViewModelProvider] (C7 list),
  ///   · [profileViewModelProvider] (C9 header's MI-11 freshness ring —
  ///     D16: the ring must re-derive after every capture/delete).
  /// The two-surface contract test pins this list; extending the fan-out
  /// means extending the test.
  ///
  /// keepAlive for the ratified orchestration reason: a read-only
  /// controller must not unmount its Ref across the repository await.
  VaultActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vaultActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vaultActionsHash();

  @$internal
  @override
  VaultActions create() => VaultActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$vaultActionsHash() => r'2aed595a09196a064c58b499925d5ecad32f6bbd';

/// The vault mutation façade (the interaction audit's CLASS 1 lock):
/// every session save/delete routes through here, and ONLY here —
/// `ref.invalidate` on vault surfaces outside this façade is banned.
///
/// DECLARED invalidation fan-out — save/delete ⇒
///   · [vaultViewModelProvider] (C7 list),
///   · [profileViewModelProvider] (C9 header's MI-11 freshness ring —
///     D16: the ring must re-derive after every capture/delete).
/// The two-surface contract test pins this list; extending the fan-out
/// means extending the test.
///
/// keepAlive for the ratified orchestration reason: a read-only
/// controller must not unmount its Ref across the repository await.

abstract class _$VaultActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
