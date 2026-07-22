import 'dart:async';
import 'dart:math' as math;

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/app_haptics.dart';
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
import 'package:flutter/semantics.dart';
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
        AppHaptics.error();
      }
      // Auto-capture a11y (QA-convergence ruling: no shutter exists) —
      // announce the 3-2-1 arming and the capture firing; the ring's
      // live region carries the per-tick counts in between.
      final wasCounting = previous?.countdown != null;
      if (next.countdown != null && !wasCounting) {
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            l10n.captureCountdownA11y,
            Directionality.of(context),
          ),
        );
      }
      if (wasCounting &&
          next.countdown == null &&
          next.step == CaptureStep.processing) {
        unawaited(
          SemanticsService.sendAnnouncement(
            View.of(context),
            l10n.captureCapturedA11y,
            Directionality.of(context),
          ),
        );
      }
    });

    // The dev-flavor QC selector rides the fake camera — the §10 dev
    // seam. Prod's live camera never renders it.
    final camera = ref.watch(cameraServiceProvider);
    final devSelector = camera is CameraServiceFake
        ? _DevScenarioAction(camera: camera)
        : null;

    // The camera/countdown, QC-hint and processing steps are FULL-BLEED
    // on-media surfaces (canvas 173:574 / 266:8419 / 266:8446): true-black
    // ground, transparent over-media chrome, controls overlaid — the
    // screen is the viewport. Height/results/permission keep the sub bar.
    final immersive = switch (state.step) {
      CaptureStep.camera ||
      CaptureStep.qcFail ||
      CaptureStep.processing => true,
      _ => false,
    };
    // Processing is not escapable mid-flight (the canvas frame carries
    // no back affordance; the fake pipeline resolves on its own).
    final processing = state.step == CaptureStep.processing;
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        const HomeRoute().go(context);
      }
    }

    return Scaffold(
      backgroundColor: immersive ? const Color(0xFF000000) : null,
      extendBodyBehindAppBar: immersive,
      appBar: AppTopBar(
        kind: immersive ? AppTopBarKind.overMedia : AppTopBarKind.sub,
        title: immersive ? null : l10n.captureTitle,
        onBack: processing ? null : back,
        trailing: processing ? null : devSelector,
      ),
      body: switch (state.step) {
        CaptureStep.height => SafeArea(
          child: _HeightStep(state: state, viewModel: viewModel),
        ),
        CaptureStep.camera => _CameraStep(state: state, camera: camera),
        CaptureStep.processing => _ProcessingStep(state: state),
        CaptureStep.qcFail => _QcFailStep(state: state, viewModel: viewModel),
        CaptureStep.results => SafeArea(
          child: _ResultsStep(state: state, viewModel: viewModel),
        ),
        CaptureStep.permission => SafeArea(
          child: Center(
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
        ),
      },
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

/// The on-media secondary text tone — the dark-mode `text-2` value used
/// as a raw constant on the full-bleed capture surfaces (the documented
/// on-media token exception, design.md §2).
const Color _onMediaWhite = Color(0xFFFFFFFF);
const Color _onMediaText2 = Color(0xFFA8A8A8);

/// The quiet on-media text action ("Enter manually instead" on the
/// viewfinder's controls layer) — raw white per the on-media exception;
/// a quiet Button would paint theme `text` (black in light).
class _OnMediaTextAction extends StatelessWidget {
  const _OnMediaTextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: typography.body14.copyWith(
              fontWeight: FontWeight.w600,
              color: _onMediaWhite,
            ),
          ),
        ),
      ),
    );
  }
}

/// Viewfinder step — the Capture Kit overlay (silhouette, MI-12) FULL
/// BLEED over the camera seam's preview (canvas 173:574/266:8419). No
/// shutter exists (QA-convergence ruling, canvas+docs): the ViewModel
/// arms the 3-2-1 once the camera is live and capture fires on
/// completion; the controls layer keeps only the manual-entry escape,
/// and the over-media AppBar's back chevron cancels out of the flow.
class _CameraStep extends StatelessWidget {
  const _CameraStep({
    required this.state,
    required this.camera,
  });

  final CaptureState state;
  final CameraService camera;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final counting = state.countdown != null;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CaptureOverlay(
          expand: true,
          guide: counting ? CaptureGuide.countdown : CaptureGuide.searching,
          countdown: state.countdown ?? CountdownCount.three,
          child: state.cameraReady ? camera.buildPreview() : null,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _OnMediaTextAction(
                label: l10n.captureEnterManually,
                onTap: () => const ManualEntryRoute().pushReplacement(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Processing step — the true-black on-media surface (canvas 266:8446):
/// constellation card centred, "Measuring…" + the landmark detail line
/// beneath it; the module's own status caption stays hidden here.
class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({required this.state});

  final CaptureState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = Theme.of(context).extension<AppTypography>()!;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min<double>(constraints.maxWidth, 280);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: ProcessingConstellation(
                      state: ProcessingState.processing,
                      showStatus: false,
                      image: state.photoBytes == null
                          ? null
                          : MemoryImage(state.photoBytes!),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.captureProcessingTitle,
                      textAlign: TextAlign.center,
                      style: typography.title24Bold.copyWith(
                        color: _onMediaWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.captureProcessingBody,
                    textAlign: TextAlign.center,
                    style: typography.body14.copyWith(color: _onMediaText2),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// QC-fail step — ONE actionable retake instruction (first failure only,
/// capture-qc.md reporting rule), mapped 1:1 onto the QCHintChip codes,
/// full-bleed over the rejected frame like the viewfinder it returns to.
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

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // The chip rides 24px above the overlay bottom — pad the overlay
        // up past the controls layer so they never collide.
        Positioned.fill(
          bottom: 128,
          child: CaptureOverlay(
            expand: true,
            guide: CaptureGuide.qcHint,
            qcCode: code,
            child: bytes == null
                ? null
                : Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Button(
                    label: l10n.captureRetake,
                    expand: true,
                    onPressed: viewModel.retake,
                  ),
                  const SizedBox(height: 8),
                  // Manual fallback for QC that never clears (§10).
                  _OnMediaTextAction(
                    label: l10n.captureEnterManually,
                    onTap: () =>
                        const ManualEntryRoute().pushReplacement(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final session = state.session;
    if (session == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CaptureResults(
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
          const SizedBox(height: 16),
          // The APP-005 privacy line under Save/Retake (canvas 173:597).
          Text(
            l10n.captureResultsPrivacyNote,
            style: typography.caption13.copyWith(color: colors.text2),
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
