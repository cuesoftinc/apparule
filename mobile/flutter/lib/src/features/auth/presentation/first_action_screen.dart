import 'dart:async';

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/data/first_action_flag.dart';
import 'package:apparule/src/features/measurements/presentation/capture_launcher.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C1b — the post-signup interstitial (canvas 266:2 "Welcome, choose
/// your start"; pages.md C1b): "Take your first measurement" (→ C6) or
/// "Explore outfits" (→ C3), skippable. The router's auth redirect hands
/// a FIRST sign-in off here (flows/auth.md §3 → pages.md C1); any exit
/// flips the persisted flag so later sign-ins go straight home.
class FirstActionScreen extends ConsumerWidget {
  const FirstActionScreen({super.key});

  /// First name from the Google-asserted profile ("Kiki Adeyemi" →
  /// "Kiki"); the bare username fallback keeps the greeting personal
  /// even when the profile carries no display name.
  static String _firstName(String? displayName) {
    final name = displayName?.trim() ?? '';
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    void Function(BuildContext context) navigate,
  ) async {
    await ref.read(firstActionFlagProvider.notifier).markSeen();
    if (context.mounted) navigate(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final spacing = theme.extension<AppSpacing>()!;
    final typography = theme.extension<AppTypography>()!;
    final session = ref.watch(authSessionProvider).value;
    final name = _firstName(session?.displayName);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: spacing.s4),
          children: <Widget>[
            SizedBox(height: spacing.s16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.s2),
              child: Text(
                l10n.firstActionTitle(name),
                style: typography.title24Bold.copyWith(color: colors.text),
              ),
            ),
            SizedBox(height: spacing.s3),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.s2),
              child: Text(
                l10n.firstActionSubtitle,
                style: typography.body14.copyWith(color: colors.text2),
              ),
            ),
            SizedBox(height: spacing.s8),
            _ChoiceCard(
              icon: LucideIcons.camera,
              title: l10n.firstActionMeasure,
              meta: l10n.firstActionMeasureMeta,
              // → C6: the capture entry gesture (guide on first run).
              // Interstitial exits always `go()` first (D72 — the audit's
              // CLASS 7 convention): backing out of capture must land on
              // home, never on the already-dismissed C1b.
              onTap: () => _leave(context, ref, (context) {
                const HomeRoute().go(context);
                unawaited(launchCaptureFlow(context, ref));
              }),
            ),
            SizedBox(height: spacing.s8),
            _ChoiceCard(
              icon: LucideIcons.search,
              title: l10n.firstActionExplore,
              meta: l10n.firstActionExploreMeta,
              onTap: () => _leave(
                context,
                ref,
                (context) => const ExploreRoute().go(context),
              ),
            ),
            SizedBox(height: spacing.s12),
            Center(
              child: Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => unawaited(
                    _leave(
                      context,
                      ref,
                      (context) => const HomeRoute().go(context),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.s2),
                    child: Text(
                      l10n.firstActionSkip,
                      style: typography.body14.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.link,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One canvas 266:6 choice card: 28px glyph · title + one-line meta ·
/// trailing chevron, on the elevated surface.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final spacing = theme.extension<AppSpacing>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      button: true,
      label: '$title. $meta',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(spacing.s4),
          decoration: BoxDecoration(
            color: colors.bgElev,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(radii.card),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 28, color: colors.text),
              SizedBox(width: spacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: typography.body16SemiBold.copyWith(
                        color: colors.text,
                      ),
                    ),
                    SizedBox(height: spacing.s1),
                    Text(
                      meta,
                      style: typography.caption13.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.s2),
              Icon(LucideIcons.chevronRight, size: 20, color: colors.text),
            ],
          ),
        ),
      ),
    );
  }
}
