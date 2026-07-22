import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/app_theme.dart';
import 'package:apparule/src/core/theme/theme_mode_controller.dart';
import 'package:apparule/src/routing/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MaterialApp.router over the typed router, token themes (light + dark
/// from the same set, §7) switched by the persisted tri-state preference
/// (B7 Appearance), and the en-only l10n pipeline.
class ApparuleApp extends ConsumerWidget {
  const ApparuleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeControllerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
