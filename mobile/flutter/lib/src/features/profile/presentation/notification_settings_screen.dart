import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/app_switch.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:apparule/src/features/profile/presentation/settings_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B7 sub-screen — Notifications (canvas 207:2): the seven per-event
/// toggles, optimistic per MI-18 (the ViewModel flips the snapshot and
/// rolls back on failure). Payment receipts and delivery confirmations
/// are always sent — footer copy, no toggle.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(settingsViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.settingsNotificationsRow,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const SettingsRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value?) => _PrefsList(prefs: value.notificationPrefs),
        AsyncData() => Center(child: Text(l10n.profileSignedOut)),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PrefsList extends ConsumerWidget {
  const _PrefsList({required this.prefs});

  final NotificationPrefs prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    Future<void> set(NotificationPrefs updated) => ref
        .read(settingsViewModelProvider.notifier)
        .setNotificationPrefs(updated);

    // (label, current value, the prefs snapshot a toggle flips to) — a
    // switch is always a flip, so the target state precomputes.
    final rows = <(String, bool, NotificationPrefs)>[
      (
        l10n.notifPrefQuotesOrderStatus,
        prefs.quotesOrderStatus,
        prefs.copyWith(quotesOrderStatus: !prefs.quotesOrderStatus),
      ),
      (
        l10n.notifPrefNewRequests,
        prefs.newRequests,
        prefs.copyWith(newRequests: !prefs.newRequests),
      ),
      (
        l10n.notifPrefLikesComments,
        prefs.likesComments,
        prefs.copyWith(likesComments: !prefs.likesComments),
      ),
      (
        l10n.notifPrefNewFollowers,
        prefs.newFollowers,
        prefs.copyWith(newFollowers: !prefs.newFollowers),
      ),
      (
        l10n.notifPrefFreshOutfits,
        prefs.freshOutfits,
        prefs.copyWith(freshOutfits: !prefs.freshOutfits),
      ),
      (
        l10n.notifPrefFreshnessReminders,
        prefs.freshnessReminders,
        prefs.copyWith(freshnessReminders: !prefs.freshnessReminders),
      ),
      (
        l10n.notifPrefEmailDigest,
        prefs.emailDigest,
        prefs.copyWith(emailDigest: !prefs.emailDigest),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        for (final (label, value, flipped) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: typography.body14.copyWith(color: colors.text),
                  ),
                ),
                AppSwitch(
                  value: value,
                  onChanged: (_) => set(flipped),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.notifPrefAlwaysSent,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
      ],
    );
  }
}
