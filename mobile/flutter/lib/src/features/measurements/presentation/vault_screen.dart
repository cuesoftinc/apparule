import 'dart:async';
import 'dart:convert';

import 'package:apparule/src/core/async/run_action.dart';
import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/capture_option_card.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/core/ui/skeleton.dart';
import 'package:apparule/src/core/utils/clock.dart';
import 'package:apparule/src/core/utils/formats.dart';
import 'package:apparule/src/core/utils/seed_media.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/domain/measurement_share.dart';
import 'package:apparule/src/features/measurements/presentation/capture_launcher.dart';
import 'package:apparule/src/features/measurements/presentation/vault_actions.dart';
import 'package:apparule/src/features/measurements/presentation/vault_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// C7 — the measurement vault (pages.md C7 = B4 adapted; canvas
/// 173:698): the MI-11 freshness-ring header with the Retake entry (the
/// capture-options sheet), one MeasurementCard per METRIC with its
/// cross-session sparkline (tap → history sheet: session rows + delete),
/// and the consent/retention note with the B4 rights links.
class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(vaultViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.vaultTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            // Deep-linked with an empty stack: the vault's shell entry
            // point is the Profile tab (pages.md C7).
            const ProfileRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value) => _VaultBody(sessions: value),
        // Load-error recovery (D47, web VaultView parity): recovery copy
        // + Retry, never raw error text.
        AsyncError() => const _VaultLoadError(),
        _ => const _VaultSkeleton(),
      },
    );
  }
}

/// The C7 load-error state — "The vault couldn't load — try again" with
/// a quiet Retry re-deriving the list (MI-19: skeletons never spin
/// forever; errors land on a recovery state).
class _VaultLoadError extends ConsumerWidget {
  const _VaultLoadError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.vaultLoadError,
              textAlign: TextAlign.center,
              style: typography.body14.copyWith(color: colors.text2),
            ),
            const SizedBox(height: 16),
            Button(
              label: l10n.vaultRetry,
              kind: ButtonKind.quiet,
              onPressed: () => ref.invalidate(vaultViewModelProvider),
            ),
          ],
        ),
      ),
    );
  }
}

/// The B4/C7 capture-options sheet — camera / manual entry (MI-13);
/// shared by the header Retake AND the empty-vault CTA (D17: manual
/// entry must be reachable from an empty vault too).
Future<void> _showCaptureOptionsSheet(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  return Sheet.show<void>(
    context,
    title: l10n.vaultRetakeSheetTitle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CaptureOptionCard(
          mode: CaptureOptionMode.photoUpload,
          onTap: () {
            Navigator.of(context).pop();
            unawaited(launchCaptureFlow(context, ref));
          },
        ),
        const SizedBox(height: 12),
        CaptureOptionCard(
          mode: CaptureOptionMode.manualEntry,
          onTap: () {
            Navigator.of(context).pop();
            unawaited(const ManualEntryRoute().push<void>(context));
          },
        ),
      ],
    ),
  );
}

/// The C7-loading frame (canvas 212:5983): header block over card blocks
/// (MI-19 — skeletons, never a bare spinner, on list loads).
class _VaultSkeleton extends StatelessWidget {
  const _VaultSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        Row(
          children: <Widget>[
            Skeleton(kind: SkeletonKind.avatar),
            SizedBox(width: 16),
            Expanded(child: Skeleton()),
          ],
        ),
        SizedBox(height: 24),
        Skeleton(),
        SizedBox(height: 12),
        Skeleton(),
        SizedBox(height: 12),
        Skeleton(),
      ],
    );
  }
}

/// One metric's latest value + its cross-session history (the canvas
/// metric-centric vault: cards per measure, not per session).
typedef _MetricEntry = ({
  String name,
  Measurement latest,
  MeasurementSession latestSession,
  List<double> history,
  DateTime updatedAt,
});

class _VaultBody extends ConsumerWidget {
  const _VaultBody({required this.sessions});

  /// Newest first (repository order).
  final List<MeasurementSession> sessions;

  /// Folds the session list into metric rows: latest value per metric,
  /// oldest→newest history for the sparkline, metric order following
  /// first appearance from the newest session down (canvas order).
  static List<_MetricEntry> _metrics(List<MeasurementSession> sessions) {
    final names = <String>[];
    final byName =
        <String, List<(DateTime, Measurement, MeasurementSession)>>{};
    for (final session in sessions) {
      for (final measurement in session.measurements) {
        if (!names.contains(measurement.name)) names.add(measurement.name);
        (byName[measurement.name] ??=
                <(DateTime, Measurement, MeasurementSession)>[])
            .add((session.createdAt, measurement, session));
      }
    }
    return <_MetricEntry>[
      for (final name in names)
        (
          name: name,
          latest: byName[name]!.first.$2,
          latestSession: byName[name]!.first.$3,
          history: <double>[
            for (final row in byName[name]!.reversed) row.$2.valueCm,
          ],
          updatedAt: byName[name]!.first.$1,
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    if (sessions.isEmpty) {
      // Canvas 212:5925: the empty vault is the EmptyState alone — the
      // capture options live behind its CTA (D17: the CTA opens the
      // options sheet, so manual entry is reachable here too).
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            kind: EmptyStateKind.vault,
            onCta: () => unawaited(_showCaptureOptionsSheet(context, ref)),
          ),
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    final metrics = _metrics(sessions);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _VaultHeader(
          newest: sessions.first,
          measurementCount: metrics.length,
          now: now,
          latestValues: <Measurement>[for (final m in metrics) m.latest],
        ),
        const SizedBox(height: 24),
        for (final metric in metrics)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MeasurementCard(
              name: metric.name,
              valueCm: metric.latest.valueCm,
              source: metric.latestSession.isManual
                  ? MeasurementSource.manual
                  : MeasurementSource.scan,
              confidence: metric.latest.confidence,
              history: metric.history,
              updatedLabel: _updatedLabel(l10n, metric.updatedAt, now),
              onTap: () => unawaited(
                _showHistorySheet(context, metric.name),
              ),
            ),
          ),
        const SizedBox(height: 4),
        // Consent + retention notice inline (canvas 173:698;
        // data-model.md §4) with the B4 rights links — both resolve at
        // the B7 Account & data screen (pages.md B7 sub-screens).
        Text(
          l10n.vaultConsentNote,
          style: typography.caption13.copyWith(color: colors.text2),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _RightsLink(
              label: l10n.vaultDownloadData,
              onTap: () => const AccountDataRoute().push<void>(context),
            ),
            Text('·', style: typography.body14.copyWith(color: colors.text2)),
            _RightsLink(
              label: l10n.vaultDeleteAll,
              onTap: () => const AccountDataRoute().push<void>(context),
            ),
          ],
        ),
      ],
    );
  }

  static String _updatedLabel(
    AppLocalizations l10n,
    DateTime at,
    DateTime now,
  ) {
    final ago = formatAgo(at, now: now);
    return ago == 'now' ? l10n.vaultUpdatedJustNow : l10n.vaultUpdatedAgo(ago);
  }

  Future<void> _showHistorySheet(BuildContext context, String metricName) {
    return Sheet.show<void>(
      context,
      title: context.l10n.vaultHistoryTitle(humanizeMeasureName(metricName)),
      child: _HistorySheet(metricName: metricName),
    );
  }
}

/// The MI-11 vault header (canvas 173:698): freshness-ring avatar,
/// "Measured N days ago", "{state} · N measurements", Retake → the
/// capture-options sheet.
class _VaultHeader extends ConsumerWidget {
  const _VaultHeader({
    required this.newest,
    required this.measurementCount,
    required this.now,
    required this.latestValues,
  });

  final MeasurementSession newest;
  final int measurementCount;
  final DateTime now;

  /// A-11: the Share action's payload — latest value per metric.
  final List<Measurement> latestValues;

  /// Share options sheet offering Text, PDF, and CSV.
  Future<void> _shareMeasurements(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final format = await Sheet.show<_ShareFormat>(
      context,
      title: l10n.vaultShareSheetTitle,
      child: const _ShareOptionsSheet(),
    );
    if (format == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final copied = l10n.vaultShareCopied;
    final repository = ref.read(measurementRepositoryProvider);
    final dateStr = newest.createdAt.toIso8601String().split('T').first;

    switch (format) {
      case _ShareFormat.text:
        final text = measurementsShareText(latestValues);
        try {
          await SharePlus.instance.share(ShareParams(text: text));
        } on Object {
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            messenger.showSnackBar(SnackBar(content: Text(copied)));
          }
        }
      case _ShareFormat.pdf:
        final fileName = 'apparule-session-$dateStr.pdf';
        try {
          final bytes = await repository.exportSessionPdf(newest.id);
          final file = XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: fileName,
          );
          await SharePlus.instance.share(
            ShareParams(
              files: <XFile>[file],
              fileNameOverrides: <String>[fileName],
            ),
          );
        } on Object {
          final text = measurementsShareText(latestValues);
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            messenger.showSnackBar(SnackBar(content: Text(copied)));
          }
        }
      case _ShareFormat.csv:
        final fileName = 'apparule-session-$dateStr.csv';
        try {
          final csv = await repository.exportSessionCsv(newest.id);
          final file = XFile.fromData(
            utf8.encode(csv),
            mimeType: 'text/csv',
            name: fileName,
          );
          await SharePlus.instance.share(
            ShareParams(
              files: <XFile>[file],
              fileNameOverrides: <String>[fileName],
            ),
          );
        } on Object {
          final csv = await repository.exportSessionCsv(newest.id);
          await Clipboard.setData(ClipboardData(text: csv));
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.vaultExportedToast)),
            );
          }
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final profile = ref.watch(profileViewModelProvider).value?.profile;

    final days = now.difference(newest.createdAt).inDays;
    // MI-11 ladder: gradient <30d · amber 30–90d · gray >90d.
    final (AvatarRing ring, String stateLabel) = days < 30
        ? (AvatarRing.gradient, l10n.vaultFreshnessFresh)
        : days <= 90
        ? (AvatarRing.amber, l10n.vaultFreshnessAging)
        : (AvatarRing.gray, l10n.vaultFreshnessStale);

    return Row(
      children: <Widget>[
        Avatar(
          name: profile?.displayName ?? '',
          image: seedMediaImageOrNull(profile?.avatarUrl),
          size: AvatarSize.s96,
          ring: ring,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                days < 1
                    ? l10n.vaultMeasuredToday
                    : l10n.vaultMeasuredDaysAgoLong(days),
                style: typography.body16SemiBold.copyWith(color: colors.text),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.vaultHeaderMeta(stateLabel, measurementCount),
                style: typography.caption13.copyWith(color: colors.text2),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Button(
                    label: l10n.vaultRetake,
                    kind: ButtonKind.quiet,
                    size: ButtonSize.sm,
                    onPressed: () =>
                        unawaited(_showCaptureOptionsSheet(context, ref)),
                  ),
                  const SizedBox(width: 8),
                  // A-11: share the latest values as text + link — the
                  // WhatsApp-to-tailor flow (deliberate tap; nothing
                  // shares body data by default).
                  Button(
                    label: l10n.vaultShare,
                    kind: ButtonKind.quiet,
                    size: ButtonSize.sm,
                    onPressed: () =>
                        unawaited(_shareMeasurements(context, ref)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One metric's history sheet (pages.md C7 = B4): session rows — date,
/// method chip, the value that session recorded — with per-session
/// delete.
class _HistorySheet extends ConsumerWidget {
  const _HistorySheet({required this.metricName});

  final String metricName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;
    final sessions =
        ref.watch(vaultViewModelProvider).value ?? const <MeasurementSession>[];

    final rows = <(MeasurementSession, Measurement)>[
      for (final session in sessions)
        for (final measurement in session.measurements)
          if (measurement.name == metricName) (session, measurement),
    ];

    if (rows.isEmpty) {
      // Deleting the metric's last session empties the sheet — close it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(Navigator.of(context).maybePop());
      });
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (session, measurement) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        formatMonthDayYear(session.createdAt),
                        style: typography.body14.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.isManual
                            ? l10n.vaultSessionManual
                            : l10n.vaultSessionScan,
                        style: typography.micro12.copyWith(
                          color: colors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCm(measurement.valueCm),
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Per-session export (D50, features.md F2-9; PLAT-004):
                // opens the export sheet offering PDF and CSV, handing
                // the file to the system share sheet.
                Semantics(
                  label: l10n.vaultExportSession,
                  button: true,
                  child: InkResponse(
                    radius: 20,
                    borderRadius: BorderRadius.circular(radii.pill),
                    onTap: () =>
                        unawaited(_showExportSheet(context, ref, session)),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        LucideIcons.download,
                        size: 18,
                        color: colors.text2,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label: l10n.vaultDeleteSession,
                  button: true,
                  child: InkResponse(
                    radius: 20,
                    borderRadius: BorderRadius.circular(radii.pill),
                    onTap: () => unawaited(_delete(context, ref, session.id)),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: colors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Delete through the VaultActions façade inside `runAction` (D48 +
  /// D16): success lands the "Session deleted" toast, failure the shared
  /// rollback toast — never silent either way.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    final l10n = context.l10n;
    final ok = await runAction(
      context,
      () => ref.read(vaultActionsProvider.notifier).deleteSession(sessionId),
    );
    if (ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.vaultSessionDeleted)));
    }
  }

  Future<void> _showExportSheet(
    BuildContext context,
    WidgetRef ref,
    MeasurementSession session,
  ) async {
    final l10n = context.l10n;
    final format = await Sheet.show<_ExportFormat>(
      context,
      title: l10n.vaultExportSheetTitle,
      child: const _ExportOptionsSheet(),
    );
    if (format == null || !context.mounted) return;
    await _export(context, ref, session, format);
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    MeasurementSession session,
    _ExportFormat format,
  ) async {
    final l10n = context.l10n;
    final repository = ref.read(measurementRepositoryProvider);
    await runAction(context, () async {
      final dateStr = session.createdAt.toIso8601String().split('T').first;
      final XFile file;
      final String fileName;
      switch (format) {
        case _ExportFormat.pdf:
          final bytes = await repository.exportSessionPdf(session.id);
          fileName = 'apparule-session-$dateStr.pdf';
          file = XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: fileName,
          );
        case _ExportFormat.csv:
          final csv = await repository.exportSessionCsv(session.id);
          fileName = 'apparule-session-$dateStr.csv';
          file = XFile.fromData(
            utf8.encode(csv),
            mimeType: 'text/csv',
            name: fileName,
          );
      }
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[file],
            fileNameOverrides: <String>[fileName],
          ),
        );
      } on Object {
        if (format == _ExportFormat.csv) {
          final csv = await repository.exportSessionCsv(session.id);
          await Clipboard.setData(ClipboardData(text: csv));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.vaultExportedToast)));
          }
        }
      }
    });
  }
}

enum _ShareFormat { text, pdf, csv }

class _ShareOptionsSheet extends StatelessWidget {
  const _ShareOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ExportOptionRow(
          label: l10n.vaultShareText,
          icon: LucideIcons.messageSquare,
          onTap: () => Navigator.of(context).pop(_ShareFormat.text),
        ),
        _ExportOptionRow(
          label: l10n.vaultExportPdf,
          icon: LucideIcons.fileText,
          onTap: () => Navigator.of(context).pop(_ShareFormat.pdf),
        ),
        _ExportOptionRow(
          label: l10n.vaultExportCsv,
          icon: LucideIcons.fileSpreadsheet,
          onTap: () => Navigator.of(context).pop(_ShareFormat.csv),
        ),
      ],
    );
  }
}

enum _ExportFormat { pdf, csv }

class _ExportOptionsSheet extends StatelessWidget {
  const _ExportOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ExportOptionRow(
          label: l10n.vaultExportPdf,
          icon: LucideIcons.fileText,
          onTap: () => Navigator.of(context).pop(_ExportFormat.pdf),
        ),
        _ExportOptionRow(
          label: l10n.vaultExportCsv,
          icon: LucideIcons.fileSpreadsheet,
          onTap: () => Navigator.of(context).pop(_ExportFormat.csv),
        ),
      ],
    );
  }
}

class _ExportOptionRow extends StatelessWidget {
  const _ExportOptionRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: colors.text),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: colors.text2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RightsLink extends StatelessWidget {
  const _RightsLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: typography.body14.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.link,
          ),
        ),
      ),
    );
  }
}
