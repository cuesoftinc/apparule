import 'dart:async';
import 'dart:math' as math;

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/capture_overlay.dart';
import 'package:apparule/src/core/ui/capture_results.dart';
import 'package:apparule/src/core/ui/countdown_ring.dart';
import 'package:apparule/src/core/ui/empty_state.dart';
import 'package:apparule/src/core/ui/manual_measure_row.dart';
import 'package:apparule/src/core/ui/measurement_card.dart';
import 'package:apparule/src/core/ui/processing_constellation.dart';
import 'package:apparule/src/core/ui/qc_hint_chip.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/features/measurements/data/camera_service.dart';
import 'package:apparule/src/features/measurements/data/camera_service_fake.dart';
import 'package:apparule/src/features/measurements/data/capture_sample_catalog.dart';
import 'package:apparule/src/features/measurements/presentation/capture_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// C6 — measurement capture (mobile-implementation.md §10; pages.md C6):
/// height step → viewfinder (Capture Kit silhouette overlay + 3-2-1) →
/// processing constellation → results stagger | first-failure QC hint,
/// with the camera-permission dead end and the MI-13 manual fallback.
class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(captureViewModelProvider);
    final viewModel = ref.read(captureViewModelProvider.notifier);

    ref.listen(captureViewModelProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        // Save landed → the vault lists it (C7).
        const VaultRoute().go(context);
      }
      if (next.step == CaptureStep.qcFail &&
          previous?.step != CaptureStep.qcFail) {
        // MI-20: error buzz on capture failed.
        unawaited(HapticFeedback.vibrate());
      }
    });

    // The dev-flavor QC selector rides the fake camera — the §10 dev
    // seam. Prod's live camera never renders it.
    final camera = ref.watch(cameraServiceProvider);
    final devSelector = camera is CameraServiceFake
        ? _DevScenarioAction(camera: camera)
        : null;

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.captureTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const HomeRoute().go(context);
          }
        },
        trailing: devSelector,
      ),
      body: SafeArea(
        child: switch (state.step) {
          CaptureStep.height => _HeightStep(state: state, viewModel: viewModel),
          CaptureStep.camera => _CameraStep(
            state: state,
            viewModel: viewModel,
            camera: camera,
          ),
          CaptureStep.processing => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              // Size the 3:4 constellation to whichever axis binds, so
              // the module never overflows short viewports.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(
                    constraints.maxWidth,
                    // 3:4 media + the ~48px status line beneath it.
                    (constraints.maxHeight - 48) * 3 / 4,
                  );
                  return SizedBox(
                    width: math.max(width, 120),
                    child: ProcessingConstellation(
                      state: ProcessingState.processing,
                      image: state.photoBytes == null
                          ? null
                          : MemoryImage(state.photoBytes!),
                    ),
                  );
                },
              ),
            ),
          ),
          CaptureStep.qcFail => _QcFailStep(state: state, viewModel: viewModel),
          CaptureStep.results => _ResultsStep(
            state: state,
            viewModel: viewModel,
          ),
          CaptureStep.permission => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EmptyState(
                kind: EmptyStateKind.cameraPermission,
                onCta: _openSystemSettings,
                onSecondaryCta: () =>
                    const ManualEntryRoute().pushReplacement(context),
              ),
            ),
          ),
        },
      ),
    );
  }

  /// Settings deep-link (flows/vault.md §1 camera-permission edge case).
  /// iOS resolves `app-settings:`; platforms that can't are a silent
  /// no-op until a settings plugin is ratified into the pin ledger.
  static Future<void> _openSystemSettings() async {
    final uri = Uri.parse('app-settings:');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

/// Height step — collected once per session (`user_height_cm`, api.md
/// `POST /measure`), pre-filled from the newest session, hard-gated to
/// the flows/vault.md 100–230 cm band (an implausible scale input breaks
/// every output; manual-entry ranges stay advisory by contrast).
class _HeightStep extends StatelessWidget {
  const _HeightStep({required this.state, required this.viewModel});

  final CaptureState state;
  final CaptureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.captureHeightTitle,
            style: typography.title20SemiBold.copyWith(color: colors.text),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.captureHeightBody,
            style: typography.caption13.copyWith(color: colors.text2),
          ),
          const SizedBox(height: 24),
          ManualMeasureRow(
            name: 'height',
            valueCm: state.heightCm,
            min: kMinHeightCm,
            max: kMaxHeightCm,
            unit: state.unit,
            onChanged: viewModel.setHeight,
            onUnitChanged: viewModel.setUnit,
            error: state.heightInvalid ? l10n.captureHeightError : null,
          ),
          const Spacer(),
          Button(
            label: l10n.captureHeightContinue,
            expand: true,
            onPressed: viewModel.continueToCamera,
          ),
        ],
      ),
    );
  }
}

/// Viewfinder step — the Capture Kit overlay (silhouette, MI-12) over the
/// camera seam's preview; the shutter runs the 3-2-1 countdown.
class _CameraStep extends StatelessWidget {
  const _CameraStep({
    required this.state,
    required this.viewModel,
    required this.camera,
  });

  final CaptureState state;
  final CaptureViewModel viewModel;
  final CameraService camera;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    final counting = state.countdown != null;
    final canCapture = state.cameraReady && !counting;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: CaptureOverlay(
                guide: counting
                    ? CaptureGuide.countdown
                    : CaptureGuide.searching,
                countdown: state.countdown ?? CountdownCount.three,
                child: state.cameraReady ? camera.buildPreview() : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: l10n.captureShutterLabel,
            button: true,
            enabled: canCapture,
            // The gradient disc + glyph are presentational.
            excludeSemantics: true,
            child: InkResponse(
              onTap: canCapture ? viewModel.startCountdown : null,
              radius: 44,
              child: Opacity(
                opacity: canCapture ? 1 : 0.5,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: colors.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    size: 28,
                    color: colors.onAccent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Button(
            label: l10n.captureEnterManually,
            kind: ButtonKind.quiet,
            onPressed: () => const ManualEntryRoute().pushReplacement(context),
          ),
        ],
      ),
    );
  }
}

/// QC-fail step — ONE actionable retake instruction (first failure only,
/// capture-qc.md reporting rule), mapped 1:1 onto the QCHintChip codes.
class _QcFailStep extends StatelessWidget {
  const _QcFailStep({required this.state, required this.viewModel});

  final CaptureState state;
  final CaptureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wire = state.qcFailCode;
    final code = wire == null ? null : QcFailCode.fromWireName(wire);
    final bytes = state.photoBytes;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: CaptureOverlay(
                guide: CaptureGuide.qcHint,
                qcCode: code,
                child: bytes == null
                    ? null
                    : Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Button(
            label: l10n.captureRetake,
            expand: true,
            onPressed: viewModel.retake,
          ),
          const SizedBox(height: 8),
          // Manual fallback for QC that never clears (§10).
          Button(
            label: l10n.captureEnterManually,
            kind: ButtonKind.quiet,
            onPressed: () => const ManualEntryRoute().pushReplacement(context),
          ),
        ],
      ),
    );
  }
}

/// Results step — MeasurementCards stagger in with per-measurement
/// confidence (capture-qc.md §4); "Save to vault" primary, "Retake" quiet.
class _ResultsStep extends StatelessWidget {
  const _ResultsStep({required this.state, required this.viewModel});

  final CaptureState state;
  final CaptureViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    if (session == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CaptureResults(
        confidences: <double>[
          for (final measurement in session.measurements)
            ?measurement.confidence,
        ],
        onSave: viewModel.save,
        onRetake: viewModel.retake,
        saving: state.saving,
        children: <Widget>[
          for (final measurement in session.measurements)
            MeasurementCard(
              name: measurement.name,
              valueCm: measurement.valueCm,
              unit: state.unit,
              source: MeasurementSource.scan,
              confidence: measurement.confidence,
            ),
        ],
      ),
    );
  }
}

/// Dev-flavor-only QC selector (§10 documented seam): swaps which
/// `capture_samples.json` scenario the fake camera captures, so the
/// seeded happy path and all 11 fail codes are reproducible on demand.
class _DevScenarioAction extends ConsumerWidget {
  const _DevScenarioAction({required this.camera});

  final CameraServiceFake camera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Semantics(
      label: l10n.captureDevScenarioLabel,
      button: true,
      child: InkResponse(
        radius: 22,
        onTap: () => Sheet.show<void>(
          context,
          title: l10n.captureDevScenarioLabel,
          child: const _DevScenarioList(),
        ),
        child: Icon(LucideIcons.flaskConical, size: 20, color: colors.text2),
      ),
    );
  }
}

class _DevScenarioList extends ConsumerWidget {
  const _DevScenarioList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final catalog = ref.watch(captureSampleCatalogProvider);
    final viewModel = ref.read(captureViewModelProvider.notifier);
    final camera = ref.read(cameraServiceProvider);
    final current = camera is CameraServiceFake ? camera.sampleId : null;

    return switch (catalog) {
      AsyncData(:final value) => ListView(
        shrinkWrap: true,
        children: <Widget>[
          for (final sample in value.samples)
            InkWell(
              onTap: () {
                viewModel.selectDevSample(sample.id);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        sample.label,
                        style: typography.body14.copyWith(color: colors.text),
                      ),
                    ),
                    if (sample.id == current)
                      Icon(
                        LucideIcons.check,
                        size: 16,
                        color: colors.accentStart,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      AsyncError() => const SizedBox.shrink(),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}
