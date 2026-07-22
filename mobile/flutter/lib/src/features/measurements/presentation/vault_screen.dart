import 'dart:async';

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
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/presentation/capture_launcher.dart';
import 'package:apparule/src/features/measurements/presentation/vault_view_model.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const _VaultSkeleton(),
      },
    );
  }
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
      // capture options live behind its CTA, not above it.
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            kind: EmptyStateKind.vault,
            onCta: () => unawaited(launchCaptureFlow(context, ref)),
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
  });

  final MeasurementSession newest;
  final int measurementCount;
  final DateTime now;

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
              Align(
                alignment: Alignment.centerLeft,
                child: Button(
                  label: l10n.vaultRetake,
                  kind: ButtonKind.quiet,
                  size: ButtonSize.sm,
                  onPressed: () => unawaited(_showRetakeSheet(context, ref)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The B4 "Retake → capture options" sheet: camera / manual entry.
  Future<void> _showRetakeSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Sheet.show<void>(
      context,
      title: l10n.vaultRetakeSheetTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CaptureOptionCard(
            mode: CaptureOptionMode.webcamUpload,
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
                Semantics(
                  label: l10n.vaultDeleteSession,
                  button: true,
                  child: InkResponse(
                    radius: 20,
                    borderRadius: BorderRadius.circular(radii.pill),
                    onTap: () => unawaited(
                      ref
                          .read(vaultViewModelProvider.notifier)
                          .deleteSession(session.id),
                    ),
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
