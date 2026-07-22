import 'dart:async';

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/guide_page.dart';
import 'package:apparule/src/features/measurements/data/capture_guide_flag.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One guide step's copy — title + bullets from the ARB (re-keyed to the
/// canvas strings, the canon) over the GuidePage set's `step` axis.
typedef _GuideStepData = ({GuideStep step, String title, List<String> bullets});

/// C6's instructional guide (mobile-implementation.md §10; M-8/M-10
/// canvas-first frames 529:2441/2477/8935/8975 + 540:9172): five
/// GuidePage steps — intro · get ready · phone setup · front pose · side
/// pose — through ONE parameterized widget, replacing the 2023 navy
/// photo art with token-bound Capture Kit vectors. First entry pages
/// through all steps; once completed (persisted flag) the ➕ entry skips
/// straight to capture and re-entered guides grow a Skip (529:9015).
class CaptureGuideScreen extends ConsumerStatefulWidget {
  const CaptureGuideScreen({super.key});

  @override
  ConsumerState<CaptureGuideScreen> createState() => _CaptureGuideScreenState();
}

class _CaptureGuideScreenState extends ConsumerState<CaptureGuideScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// The five canvas steps (GuidePage set 526:33, pose split 2026-07-22).
  List<_GuideStepData> _steps(BuildContext context) {
    final l10n = context.l10n;
    return <_GuideStepData>[
      (
        step: GuideStep.intro,
        title: l10n.guideStep1Title,
        bullets: <String>[l10n.guideStep1Body1],
      ),
      (
        step: GuideStep.ready,
        title: l10n.guideStep2Title,
        bullets: <String>[l10n.guideStep2Body1, l10n.guideStep2Body2],
      ),
      (
        step: GuideStep.setup,
        title: l10n.guideStep3Title,
        bullets: <String>[
          l10n.guideStep3Body1,
          l10n.guideStep3Body2,
          // The lighting bullet — NEW canvas copy teaching the
          // poor_lighting/blurry QC checks up front.
          l10n.guideStep3Body3,
        ],
      ),
      (
        step: GuideStep.poseFront,
        title: l10n.guideStep4Title,
        bullets: <String>[l10n.guideStep4Body1, l10n.guideStep4Body2],
      ),
      (
        step: GuideStep.poseSide,
        title: l10n.guideStep5Title,
        bullets: <String>[l10n.guideStep5Body1, l10n.guideStep5Body2],
      ),
    ];
  }

  Future<void> _finish() async {
    await ref.read(captureGuideFlagProvider.notifier).markCompleted();
    if (!mounted) return;
    const CaptureRoute().pushReplacement(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final motion = theme.extension<AppMotion>()!;

    final steps = _steps(context);
    final lastPage = _currentIndex == steps.length - 1;
    // Skippable only on a REVISIT (529:9015 — persisted-flag re-entry).
    final seenBefore = ref.watch(captureGuideFlagProvider).value ?? false;

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.guideTitle,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const HomeRoute().go(context);
          }
        },
        trailing: seenBefore
            ? Button(
                label: l10n.guideSkip,
                kind: ButtonKind.link,
                size: ButtonSize.sm,
                onPressed: _finish,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: GuidePage(
                      step: step.step,
                      title: step.title,
                      bullets: step.bullets,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Semantics(
                    label: l10n.guidePageLabel(
                      _currentIndex + 1,
                      steps.length,
                    ),
                    // The dots are presentational; the label carries the
                    // position.
                    excludeSemantics: true,
                    child: Row(
                      children: <Widget>[
                        for (var i = 0; i < steps.length; i++)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentIndex
                                  ? colors.accentStart
                                  : colors.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Button(
                    label: lastPage ? l10n.guideStartCapture : l10n.guideNext,
                    onPressed: lastPage
                        ? _finish
                        : () => unawaited(
                            _pageController.nextPage(
                              duration: motion.base,
                              curve: motion.standardEasing,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
