import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/app_switch.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:apparule/src/features/profile/presentation/settings_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// B7 sub-screen — Privacy & consent (canvas 207:7155): the AI-processing
/// consent toggle (camera capture requires it; manual entry stays
/// available), the 30-day photo-retention notice (data-model.md §4), the
/// nearby-recommendations toggle (X-10 explainer copy), the consent
/// history ledger, and the canonical privacy-policy link.
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(settingsViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.settingsPrivacyRow,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const SettingsRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value?) => _PrivacyBody(profile: value),
        AsyncData() => Center(child: Text(l10n.profileSignedOut)),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PrivacyBody extends ConsumerWidget {
  const _PrivacyBody({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final prefs = profile.privacyPrefs;

    Widget sectionHeader(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(
        text,
        style: typography.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
      ),
    );

    Widget helper(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: typography.caption13.copyWith(color: colors.text2),
      ),
    );

    Widget toggleRow({
      required String label,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: typography.body14.copyWith(color: colors.text),
            ),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        sectionHeader(l10n.privacyAiSection),
        toggleRow(
          label: l10n.privacyAiToggle,
          value: prefs.aiProcessing,
          onChanged: (v) => ref
              .read(settingsViewModelProvider.notifier)
              .setPrivacyPrefs(prefs.copyWith(aiProcessing: v)),
        ),
        helper(l10n.privacyAiHelper),
        sectionHeader(l10n.privacyRetentionSection),
        helper(l10n.privacyRetentionBody),
        const SizedBox(height: 12),
        toggleRow(
          label: l10n.privacyNearbyToggle,
          value: prefs.nearbyRecommendations,
          onChanged: (v) => ref
              .read(settingsViewModelProvider.notifier)
              .setPrivacyPrefs(prefs.copyWith(nearbyRecommendations: v)),
        ),
        helper(l10n.privacyNearbyHelper),
        sectionHeader(l10n.privacyConsentSection),
        for (final record in profile.consent)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l10n.privacyConsentLine(
                switch (record.document) {
                  'tos' => l10n.privacyConsentTos,
                  'privacy' => l10n.privacyConsentPrivacy,
                  final other => other,
                },
                formatMonthDayYear(record.acceptedAt),
              ),
              style: typography.caption13.copyWith(color: colors.text2),
            ),
          ),
        const SizedBox(height: 16),
        Semantics(
          link: true,
          child: GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://privacy.cuesoft.io'),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              l10n.privacyReadPolicy,
              style: typography.body14.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.link,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
