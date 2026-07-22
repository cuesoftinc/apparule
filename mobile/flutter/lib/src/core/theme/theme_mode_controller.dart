import 'dart:async';

import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_controller.g.dart';

/// The tri-state theme preference (B7 Appearance: System / Light /
/// Dark) — hydrates from [PersistenceService] on boot and persists every
/// change (the §11 REWRITE of the legacy `persistence.dart`: a theme
/// flag is the ONE thing SharedPreferences still carries). Defaults to
/// following the system until the stored value arrives.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    unawaited(_hydrate());
    return ThemeMode.system;
  }

  Future<void> _hydrate() async {
    final stored = await ref.read(persistenceServiceProvider).readThemeMode();
    state = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(persistenceServiceProvider).writeThemeMode(mode.name);
  }
}
