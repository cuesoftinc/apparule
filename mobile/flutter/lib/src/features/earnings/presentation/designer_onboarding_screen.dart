import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/features/earnings/presentation/designer_onboarding_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// C13 — Become a designer (canvas 204:1140; pages.md B8 intro): the
/// what-you-get bullets (feed reach · requests with measurements
/// attached · escrow payouts) over the create form (username page URL
/// helper, display name, bio). Creating hands off to the payout form —
/// "Post right away — add banking details when you're ready to accept
/// requests."
class DesignerOnboardingScreen extends ConsumerStatefulWidget {
  const DesignerOnboardingScreen({super.key});

  @override
  ConsumerState<DesignerOnboardingScreen> createState() =>
      _DesignerOnboardingScreenState();
}

class _DesignerOnboardingScreenState
    extends ConsumerState<DesignerOnboardingScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  bool _hydrated = false;
  bool _creating = false;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      await ref
          .read(designerOnboardingViewModelProvider.notifier)
          .create(
            username: _username.text,
            displayName: _displayName.text,
            bio: _bio.text,
          );
      if (mounted) {
        // B8: intro → banking form. replace() keeps back = the gear.
        const PayoutAccountRoute().pushReplacement(context);
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final prefill = ref.watch(designerOnboardingViewModelProvider);

    if (prefill case AsyncData(:final value) when !_hydrated) {
      _hydrated = true;
      _username.text = value.username;
      _displayName.text = value.displayName;
    }

    OutlineInputBorder border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.card),
      borderSide: BorderSide(color: colors.border),
    );

    InputDecoration decoration({String? hint}) => InputDecoration(
      hintText: hint,
      hintStyle: typography.body14.copyWith(color: colors.text2),
      isDense: true,
      filled: true,
      fillColor: colors.bgElev,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      border: border(),
      enabledBorder: border(),
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: typography.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
      ),
    );

    Widget helper(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: typography.caption13.copyWith(color: colors.text2),
      ),
    );

    Widget bullet(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: colors.text2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: typography.body14.copyWith(color: colors.text2),
            ),
          ),
        ],
      ),
    );

    final fieldStyle = typography.body14.copyWith(color: colors.text);

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.designerOnboardingTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const SettingsRoute().go(context);
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Text(
            l10n.designerOnboardingHeadline,
            style: typography.title20SemiBold.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          bullet(LucideIcons.camera, l10n.designerOnboardingBulletFeed),
          bullet(LucideIcons.tag, l10n.designerOnboardingBulletRequests),
          bullet(LucideIcons.wallet, l10n.designerOnboardingBulletPayouts),
          label(l10n.designerOnboardingUsername),
          TextField(
            controller: _username,
            autocorrect: false,
            style: fieldStyle,
            decoration: decoration(),
            onChanged: (_) => setState(() {}),
          ),
          helper(l10n.designerOnboardingUsernameHelper(_username.text)),
          label(l10n.designerOnboardingDisplayName),
          TextField(
            controller: _displayName,
            style: fieldStyle,
            decoration: decoration(),
          ),
          helper(l10n.designerOnboardingDisplayNameHelper),
          label(l10n.designerOnboardingBio),
          TextField(
            controller: _bio,
            style: fieldStyle,
            decoration: decoration(hint: l10n.designerOnboardingBioHint),
          ),
          helper(l10n.designerOnboardingBioHelper),
          const SizedBox(height: 28),
          Button(
            label: l10n.designerOnboardingCreate,
            loading: _creating,
            expand: true,
            onPressed: _create,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.designerOnboardingFooter,
            textAlign: TextAlign.center,
            style: typography.caption13.copyWith(color: colors.text2),
          ),
        ],
      ),
    );
  }
}
