// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The tri-state theme preference (B7 Appearance: System / Light /
/// Dark) — hydrates from [PersistenceService] on boot and persists every
/// change (the §11 REWRITE of the legacy `persistence.dart`: a theme
/// flag is the ONE thing SharedPreferences still carries). Defaults to
/// following the system until the stored value arrives.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// The tri-state theme preference (B7 Appearance: System / Light /
/// Dark) — hydrates from [PersistenceService] on boot and persists every
/// change (the §11 REWRITE of the legacy `persistence.dart`: a theme
/// flag is the ONE thing SharedPreferences still carries). Defaults to
/// following the system until the stored value arrives.
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, ThemeMode> {
  /// The tri-state theme preference (B7 Appearance: System / Light /
  /// Dark) — hydrates from [PersistenceService] on boot and persists every
  /// change (the §11 REWRITE of the legacy `persistence.dart`: a theme
  /// flag is the ONE thing SharedPreferences still carries). Defaults to
  /// following the system until the stored value arrives.
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeControllerHash() =>
    r'333ca08fc78fc3887734bd01d8ba4447759b4232';

/// The tri-state theme preference (B7 Appearance: System / Light /
/// Dark) — hydrates from [PersistenceService] on boot and persists every
/// change (the §11 REWRITE of the legacy `persistence.dart`: a theme
/// flag is the ONE thing SharedPreferences still carries). Defaults to
/// following the system until the stored value arrives.

abstract class _$ThemeModeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
