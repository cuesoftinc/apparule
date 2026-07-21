import 'package:apparule/l10n/generated/app_localizations.dart';
import 'package:apparule/src/app/di.dart';
import 'package:apparule/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

/// Pumps [widget] inside the chrome every screen expects: a ProviderScope
/// over the `*Fake` repositories (mobile-implementation.md §6), the token
/// themes, and the l10n delegates.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const <Override>[],
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: <Override>[...fakeRepositoryOverrides(), ...overrides],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget,
        ),
      ),
    );
  }
}
