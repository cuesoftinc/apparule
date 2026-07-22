import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/capture_option_card.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/features/measurements/domain/measurement_session.dart';
import 'package:apparule/src/features/measurements/presentation/capture_launcher.dart';
import 'package:apparule/src/features/measurements/presentation/vault_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C7 — the measurement vault (pages.md C7 = B4 adapted): capture-entry
/// option cards (camera / manual, the B4 "Retake" pair) over the session
/// list. Sessions render their MeasurementCards with source and
/// confidence; freshness ring/history sheet land with the profile wave.
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
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _VaultBody extends ConsumerWidget {
  const _VaultBody({required this.sessions});

  final List<MeasurementSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        CaptureOptionCard(
          mode: CaptureOptionMode.webcamUpload,
          onTap: () => launchCaptureFlow(context, ref),
        ),
        const SizedBox(height: 12),
        CaptureOptionCard(
          mode: CaptureOptionMode.manualEntry,
          onTap: () => const ManualEntryRoute().push<void>(context),
        ),
        const SizedBox(height: 24),
        if (sessions.isEmpty)
          EmptyState(
            kind: EmptyStateKind.vault,
            onCta: () => launchCaptureFlow(context, ref),
          )
        else
          for (final session in sessions) _SessionGroup(session: session),
      ],
    );
  }
}

/// One vault session: method + age header over its MeasurementCards.
class _SessionGroup extends StatelessWidget {
  const _SessionGroup({required this.session});

  final MeasurementSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    final days = DateTime.now().difference(session.createdAt).inDays;
    final ageLabel = days < 1
        ? l10n.vaultMeasuredToday
        : l10n.vaultMeasuredDaysAgo(days);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  session.isManual
                      ? l10n.vaultSessionManual
                      : l10n.vaultSessionScan,
                  style: typography.body14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
              ),
              Text(
                ageLabel,
                style: typography.micro12.copyWith(color: colors.text2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final measurement in session.measurements)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MeasurementCard(
                name: measurement.name,
                valueCm: measurement.valueCm,
                source: session.isManual
                    ? MeasurementSource.manual
                    : MeasurementSource.scan,
                confidence: measurement.confidence,
              ),
            ),
        ],
      ),
    );
  }
}
