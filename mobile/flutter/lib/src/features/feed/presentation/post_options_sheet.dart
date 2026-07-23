import 'package:apparule/src/core/async/run_action.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/features/feed/data/post_repository.dart';
import 'package:apparule/src/features/feed/domain/report_reason.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The PostCard ⋯ overflow sheet (design.md §3 Popover/MenuItem context
/// "PostCard ⋯ overflow (report/share)"; web sibling `PostOptionsSheet`):
/// copy link (the MI-9 copy target — the ActionRow share button owns the
/// native sheet) and the SOC-009 report flow behind it.
Future<void> showPostOptionsSheet(
  BuildContext context, {
  required String postId,
}) async {
  final l10n = context.l10n;
  final action = await Sheet.show<_PostOption>(
    context,
    title: l10n.postOptionsTitle,
    child: const _OptionsMenu(),
  );
  if (!context.mounted) return;
  switch (action) {
    case _PostOption.copyLink:
      await _copyPermalink(context, postId);
    case _PostOption.report:
      await Sheet.show<void>(
        context,
        title: l10n.reportTitle,
        child: _ReportForm(postId: postId),
      );
    case null:
      break;
  }
}

/// The public permalink (web-implementation.md §4 `/p/{post_id}`).
String postPermalink(String postId) => 'https://apparule.cuesoft.io/p/$postId';

Future<void> _copyPermalink(BuildContext context, String postId) async {
  final messenger = ScaffoldMessenger.of(context);
  final copied = context.l10n.feedShareCopied;
  await Clipboard.setData(ClipboardData(text: postPermalink(postId)));
  messenger.showSnackBar(SnackBar(content: Text(copied)));
}

enum _PostOption { copyLink, report }

class _OptionsMenu extends StatelessWidget {
  const _OptionsMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MenuRow(
          label: l10n.postOptionsCopyLink,
          icon: LucideIcons.copy,
          onTap: () => Navigator.of(context).pop(_PostOption.copyLink),
        ),
        _MenuRow(
          label: l10n.postOptionsReport,
          icon: LucideIcons.flag,
          destructive: true,
          onTap: () => Navigator.of(context).pop(_PostOption.report),
        ),
      ],
    );
  }
}

/// MenuItem's mobile rows-in-Sheet variant (design.md §8.2b Popover /
/// MenuItem: "desktop popover / mobile rows-in-Sheet").
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final tint = destructive ? colors.error : colors.text;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: tint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: typography.body14.copyWith(color: tint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The SOC-009 report form — reason starts unpicked and the destructive
/// CTA stays disabled until one is deliberately chosen (the danger-ladder
/// arming contract, CLASS 5; web `disabled={!reason}` parity).
class _ReportForm extends ConsumerStatefulWidget {
  const _ReportForm({required this.postId});

  final String postId;

  @override
  ConsumerState<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends ConsumerState<_ReportForm> {
  final TextEditingController _detail = TextEditingController();
  ReportReason? _reason;
  bool _submitting = false;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  String _reasonLabel(ReportReason reason) {
    final l10n = context.l10n;
    return switch (reason) {
      ReportReason.spam => l10n.reportReasonSpam,
      ReportReason.inappropriate => l10n.reportReasonInappropriate,
      ReportReason.counterfeit => l10n.reportReasonCounterfeit,
      ReportReason.harassment => l10n.reportReasonHarassment,
      ReportReason.other => l10n.reportReasonOther,
    };
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _submitting) return;
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sent = l10n.reportSentToast;
    setState(() => _submitting = true);
    final ok = await runAction(
      context,
      () => ref
          .read(postRepositoryProvider)
          .reportPost(
            widget.postId,
            reason,
            detail: _detail.text.trim().isEmpty ? null : _detail.text.trim(),
          ),
      failureText: l10n.reportFailedToast,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(sent)));
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.reportReasonLabel,
          style: typography.body14.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 8),
        for (final reason in ReportReason.values)
          Semantics(
            button: true,
            selected: _reason == reason,
            child: InkWell(
              onTap: () => setState(() => _reason = reason),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: <Widget>[
                    Icon(
                      _reason == reason
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      size: 20,
                      color: _reason == reason ? colors.text : colors.text2,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _reasonLabel(reason),
                        style: typography.body14.copyWith(color: colors.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _detail,
          maxLength: 500,
          style: typography.body14.copyWith(color: colors.text),
          decoration: InputDecoration(
            hintText: l10n.reportDetailHint,
            hintStyle: typography.body14.copyWith(color: colors.text2),
            counterText: '',
            isDense: true,
            filled: true,
            fillColor: colors.bgElev,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radii.card),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radii.card),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Button(
          label: l10n.reportSubmit,
          kind: ButtonKind.destructive,
          loading: _submitting,
          expand: true,
          // Born disarmed: no reason, no report (CLASS 5).
          onPressed: _reason == null ? null : _submit,
        ),
        const SizedBox(height: 8),
        Button(
          label: l10n.reportBack,
          kind: ButtonKind.quiet,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
