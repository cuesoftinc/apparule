import 'dart:async';

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/features/measurements/data/capture_guide_flag.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One guide page's content — the §11 REWRITE collapses the legacy's five
/// copy-pasted page classes into this record + ONE parameterized widget.
typedef _GuidePageData = ({String image, String title, List<String> bullets});

/// C6's instructional guide (mobile-implementation.md §10/§11): the
/// salvaged legacy copy and artwork, rebuilt as a single-pose flow — the
/// legacy's fifth side-pose page is the two-pose divergence the audit
/// retired, not canon. First entry pages through all steps; once
/// completed (persisted flag) the ➕ entry skips straight to capture and
/// re-entered guides grow a Skip.
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

  /// The four salvaged steps (KEEP artwork guide1/step2/guide3/guide4,
  /// §11) — frontal pose only.
  List<_GuidePageData> _pages(BuildContext context) {
    final l10n = context.l10n;
    return <_GuidePageData>[
      (
        image: 'assets/images/guide1.png',
        title: l10n.guideStep1Title,
        bullets: <String>[l10n.guideStep1Body1],
      ),
      (
        image: 'assets/images/step2.jpg',
        title: l10n.guideStep2Title,
        bullets: <String>[l10n.guideStep2Body1, l10n.guideStep2Body2],
      ),
      (
        image: 'assets/images/guide3.png',
        title: l10n.guideStep3Title,
        bullets: <String>[l10n.guideStep3Body1, l10n.guideStep3Body2],
      ),
      (
        image: 'assets/images/guide4.png',
        title: l10n.guideStep4Title,
        bullets: <String>[l10n.guideStep4Body1, l10n.guideStep4Body2],
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

    final pages = _pages(context);
    final lastPage = _currentIndex == pages.length - 1;
    // Skippable only after the first completion (§10 persisted flag).
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
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) => _GuidePage(page: pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Semantics(
                    label: l10n.guidePageLabel(
                      _currentIndex + 1,
                      pages.length,
                    ),
                    // The dots are presentational; the label carries the
                    // position.
                    excludeSemantics: true,
                    child: Row(
                      children: <Widget>[
                        for (var i = 0; i < pages.length; i++)
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

/// THE parameterized guide page — image, title, bullet copy; replaces the
/// legacy `Page1..Page5` clones (audit CV finding; §11 REWRITE).
class _GuidePage extends StatelessWidget {
  const _GuidePage({required this.page});

  final _GuidePageData page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(radii.card),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: colors.bgElev,
                child: Image.asset(page.image, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            page.title,
            style: typography.title20SemiBold.copyWith(color: colors.text),
          ),
          const SizedBox(height: 12),
          for (final bullet in page.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                bullet,
                style: typography.body14.copyWith(color: colors.text2),
              ),
            ),
        ],
      ),
    );
  }
}
