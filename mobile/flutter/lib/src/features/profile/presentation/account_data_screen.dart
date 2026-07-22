import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/banner.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:apparule/src/features/profile/presentation/settings_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B7 sub-screen — Account & data (canvas 207:7182): the Google
/// identity block, export-first ("Download my data"), and the danger
/// ladder: a QUIET-DANGER row arms the typed-confirm sheet (207:7204 —
/// type DELETE, with the "Export everything first" escape hatch); only
/// the sheet's confirm is FILLED destructive. Log out lives here per
/// the canvas. The B4 rights links resolve to this screen.
class AccountDataScreen extends ConsumerStatefulWidget {
  const AccountDataScreen({super.key});

  @override
  ConsumerState<AccountDataScreen> createState() => _AccountDataScreenState();
}

class _AccountDataScreenState extends ConsumerState<AccountDataScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await ref.read(settingsViewModelProvider.notifier).exportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountDataExportQueued)),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _armDelete() async {
    final confirmed = await showDeleteAccountSheet(context, onExport: _export);
    if (confirmed && mounted) {
      await ref.read(settingsViewModelProvider.notifier).requestDeletion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountDataDeletionRequested)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(settingsViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.settingsAccountDataRow,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const SettingsRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value?) => _AccountDataBody(
          profile: value,
          exporting: _exporting,
          onExport: _export,
          onDelete: _armDelete,
          onSignOut: () =>
              ref.read(settingsViewModelProvider.notifier).signOut(),
        ),
        AsyncData() => Center(child: Text(l10n.profileSignedOut)),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _AccountDataBody extends StatelessWidget {
  const _AccountDataBody({
    required this.profile,
    required this.exporting,
    required this.onExport,
    required this.onDelete,
    required this.onSignOut,
  });

  final Profile profile;
  final bool exporting;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    Widget sectionHeader(String text, {Color? color}) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: typography.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: color ?? colors.text,
        ),
      ),
    );

    Widget helper(String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: typography.caption13.copyWith(color: colors.text2),
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
        sectionHeader(l10n.accountDataSignedInWithGoogle),
        Text(
          profile.email,
          style: typography.body14.copyWith(color: colors.text2),
        ),
        sectionHeader(l10n.accountDataYourData),
        Button(
          label: l10n.accountDataDownload,
          kind: ButtonKind.quiet,
          expand: true,
          loading: exporting,
          onPressed: onExport,
        ),
        helper(l10n.accountDataDownloadHelper),
        sectionHeader(l10n.accountDataDangerZone, color: colors.error),
        Button(
          label: l10n.accountDataDelete,
          kind: ButtonKind.quietDanger,
          expand: true,
          onPressed: profile.deletionPending ? null : onDelete,
        ),
        helper(l10n.accountDataDeleteHelper),
        const SizedBox(height: 32),
        Button(
          label: l10n.accountDataLogOut,
          kind: ButtonKind.quiet,
          expand: true,
          onPressed: onSignOut,
        ),
      ],
    );
  }
}

/// The armed rung of the danger ladder (canvas 207:7204): typed-confirm
/// sheet — DELETE gates the filled-destructive confirm; "Export
/// everything first" is the escape hatch. Resolves true on confirm.
Future<bool> showDeleteAccountSheet(
  BuildContext context, {
  required VoidCallback onExport,
}) async {
  final confirmed = await Sheet.show<bool>(
    context,
    title: context.l10n.deleteSheetTitle,
    child: _DeleteConfirmForm(onExport: onExport),
  );
  return confirmed ?? false;
}

class _DeleteConfirmForm extends StatefulWidget {
  const _DeleteConfirmForm({required this.onExport});

  final VoidCallback onExport;

  @override
  State<_DeleteConfirmForm> createState() => _DeleteConfirmFormState();
}

class _DeleteConfirmFormState extends State<_DeleteConfirmForm> {
  final TextEditingController _confirm = TextEditingController();
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _confirm.addListener(() {
      final armed = _confirm.text.trim() == 'DELETE';
      if (armed != _armed) setState(() => _armed = armed);
    });
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.card),
      borderSide: BorderSide(color: color, width: 1.5),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.deleteSheetBody,
          style: typography.body14.copyWith(color: colors.text2),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirm,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          style: typography.body14.copyWith(color: colors.text),
          decoration: InputDecoration(
            hintText: l10n.deleteSheetTypeDelete,
            hintStyle: typography.body14.copyWith(color: colors.text2),
            isDense: true,
            filled: true,
            fillColor: colors.bgElev,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            // Canvas 207:7204: the confirm field carries the accent ring.
            border: border(colors.accentStart),
            enabledBorder: border(colors.accentStart),
            focusedBorder: border(colors.accentStart),
          ),
        ),
        const SizedBox(height: 16),
        Button(
          label: l10n.deleteSheetConfirm,
          kind: ButtonKind.destructive,
          expand: true,
          onPressed: _armed
              ? () => Navigator.of(context).pop(true)
              : null,
        ),
        const SizedBox(height: 12),
        Center(
          child: Button(
            label: l10n.deleteSheetExportFirst,
            kind: ButtonKind.link,
            onPressed: () {
              Navigator.of(context).pop(false);
              widget.onExport();
            },
          ),
        ),
        const SizedBox(height: 12),
        Button(
          label: l10n.deleteSheetCancel,
          kind: ButtonKind.quiet,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
