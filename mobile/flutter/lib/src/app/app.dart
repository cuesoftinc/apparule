import 'package:apparule/src/app/boot_screen.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/app_theme.dart';
import 'package:apparule/src/core/theme/theme_mode_controller.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/routing/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MaterialApp.router over the typed router, token themes (light + dark
/// from the same set, §7) switched by the persisted tri-state preference
/// (B7 Appearance), and the en-only l10n pipeline.
///
/// Boot gate (boot-flow directive 2026-07-22): the silent session
/// restore is an ASYNC gate above the router — until the first session
/// value lands, the app renders the branded [BootScreen] instead of
/// mounting the router, so a signed-in relaunch never flashes C1 and a
/// signed-out boot reaches C1 only once the answer is known. A failed
/// restore reads as signed out (the repository contract already maps
/// restore errors to null; the error state here is a second net).
class ApparuleApp extends ConsumerWidget {
  const ApparuleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    if (session.isLoading) {
      return MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BootScreen(),
      );
    }
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
