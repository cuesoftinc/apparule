import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/theme/theme_mode_controller.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/banner.dart';
import 'package:apparule/src/features/earnings/domain/payout.dart';
import 'package:apparule/src/features/earnings/presentation/earnings_view_model.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:apparule/src/features/profile/presentation/settings_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// B7 — settings root (C9's gear; pages.md B7 mobile-adapted): the
/// Google-identity account block, the creator-profile section (Become a
/// designer → C13, or the designer/payout status rows), the tri-state
/// Appearance control persisting via PersistenceService, the three
/// sub-screen rows (Notifications · Privacy & consent · Account & data),
/// language, and the canonical legal links. Sign-out lives on Account &
/// data per the ratified canvas (207:7182).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(settingsViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.settingsTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const ProfileRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value?) => _SettingsBody(profile: value),
        AsyncData() => Center(child: Text(l10n.profileSignedOut)),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final designer = ref.watch(designerStatusProvider).value;
    final themeMode = ref.watch(themeModeControllerProvider);

    Widget sectionHeader(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(
        text,
        style: typography.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.text2,
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        if (profile.deletionPending) ...<Widget>[
          const SizedBox(height: 8),
          AppBanner(
            tone: BannerTone.warn,
            message: l10n.settingsDeletionPendingBanner,
          ),
        ],
        sectionHeader(l10n.settingsAccountSection),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text.rich(
            TextSpan(
              style: typography.body14.copyWith(color: colors.text),
              children: <InlineSpan>[
                TextSpan(
                  text: profile.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      ' · @${profile.username} · '
                      '${l10n.settingsGoogleIdentity(profile.email)}',
                  style: TextStyle(color: colors.text2),
                ),
              ],
            ),
          ),
        ),
        sectionHeader(l10n.settingsCreatorSection),
        if (designer == null || !designer.enabled)
          _SettingsRow(
            title: l10n.settingsBecomeDesigner,
            meta: l10n.settingsBecomeDesignerMeta,
            onTap: () => const DesignerOnboardingRoute().push<void>(context),
          )
        else ...<Widget>[
          _SettingsRow(
            title: l10n.settingsDesignerActive,
            meta: switch (designer.payoutAccount?.kycState) {
              KycState.verified => l10n.settingsPayoutVerifiedMeta,
              KycState.lapsed => l10n.settingsPayoutLapsedMeta,
              _ => l10n.settingsPayoutPendingMeta,
            },
            onTap: () => const PayoutAccountRoute().push<void>(context),
          ),
          _SettingsRow(
            title: l10n.earningsTitle,
            meta: l10n.settingsEarningsMeta,
            onTap: () => const EarningsRoute().push<void>(context),
          ),
        ],
        sectionHeader(l10n.settingsAppearanceSection),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.settingsTheme,
                  style: typography.body14.copyWith(color: colors.text),
                ),
              ),
              _ThemeChoice(
                label: l10n.settingsThemeSystem,
                selected: themeMode == ThemeMode.system,
                onTap: () => ref
                    .read(themeModeControllerProvider.notifier)
                    .set(ThemeMode.system),
              ),
              const SizedBox(width: 8),
              _ThemeChoice(
                label: l10n.settingsThemeLight,
                selected: themeMode == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeControllerProvider.notifier)
                    .set(ThemeMode.light),
              ),
              const SizedBox(width: 8),
              _ThemeChoice(
                label: l10n.settingsThemeDark,
                selected: themeMode == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeControllerProvider.notifier)
                    .set(ThemeMode.dark),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.settingsLanguage,
                  style: typography.body14.copyWith(color: colors.text),
                ),
              ),
              Text(
                l10n.settingsLanguageEnglish,
                style: typography.body14.copyWith(color: colors.text2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.border),
              bottom: BorderSide(color: colors.border),
            ),
          ),
          child: Column(
            children: <Widget>[
              _SettingsRow(
                title: l10n.settingsNotificationsRow,
                meta: l10n.settingsNotificationsRowMeta,
                onTap: () =>
                    const NotificationSettingsRoute().push<void>(context),
              ),
              Divider(height: 1, color: colors.border),
              _SettingsRow(
                title: l10n.settingsPrivacyRow,
                meta: l10n.settingsPrivacyRowMeta,
                onTap: () => const PrivacySettingsRoute().push<void>(context),
              ),
              Divider(height: 1, color: colors.border),
              _SettingsRow(
                title: l10n.settingsAccountDataRow,
                meta: l10n.settingsAccountDataRowMeta,
                onTap: () => const AccountDataRoute().push<void>(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Legal footer — the canonical Cuesoft policies, the same pair
        // as the C1 footer (underlined: WCAG 1.4.1).
        Wrap(
          spacing: 16,
          children: <Widget>[
            _LegalLink(
              label: l10n.signInLegalTerms,
              uri: Uri.parse('https://terms.cuesoft.io'),
            ),
            _LegalLink(
              label: l10n.signInLegalPrivacy,
              uri: Uri.parse('https://privacy.cuesoft.io'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, required this.onTap, this.meta});

  final String title;
  final String? meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: typography.body14.copyWith(color: colors.text),
                    ),
                    if (meta case final meta?)
                      Text(
                        meta,
                        style: typography.caption13.copyWith(
                          color: colors.text2,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 20, color: colors.text2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.text : colors.bgElev,
            border: Border.all(
              color: selected ? colors.text : colors.border,
            ),
            borderRadius: BorderRadius.circular(radii.pill),
          ),
          child: Text(
            label,
            style: typography.caption13.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? colors.bg : colors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.uri});

  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      link: true,
      child: GestureDetector(
        onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
        child: Text(
          label,
          style: typography.caption13.copyWith(
            color: colors.link,
            decoration: TextDecoration.underline,
            decorationColor: colors.link,
          ),
        ),
      ),
    );
  }
}
