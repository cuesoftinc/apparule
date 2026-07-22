import 'dart:async';

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:flutter/material.dart';

/// CaptureResults — the Figma `CaptureResults` set (65:612, single
/// component); web sibling `CaptureResults.tsx`. The C6-results chrome:
/// header ("Your measurements" + confidence-summary pill) + the
/// MeasurementCard stagger-list slot (MI-12: cards rise in 60ms apart;
/// reduced motion renders them static) + "Save to vault" (gradient,
/// primary) beside "Retake" (quiet).
class CaptureResults extends StatelessWidget {
  const CaptureResults({
    required this.confidences,
    required this.children,
    required this.onSave,
    required this.onRetake,
    this.saving = false,
    super.key,
  });

  /// Per-measurement confidence values (capture-qc.md §4) — drives the
  /// header pill ("N low confidence" under 0.7, else "High confidence").
  final List<double> confidences;

  /// MeasurementCard instances — the stagger-list slot.
  final List<Widget> children;

  final VoidCallback onSave;
  final VoidCallback onRetake;

  /// Save in flight: the gradient CTA spins, Retake disables.
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final motion = theme.extension<AppMotion>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final lowCount = confidences.where((c) => c < 0.7).length;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Your measurements',
                style: typography.body16SemiBold.copyWith(color: colors.text),
              ),
            ),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (lowCount > 0 ? colors.warn : colors.success).withValues(
                  alpha: 0.14,
                ),
                borderRadius: BorderRadius.circular(radii.pill),
              ),
              child: Text(
                lowCount > 0 ? '$lowCount low confidence' : 'High confidence',
                style: typography.micro12.copyWith(
                  fontWeight: FontWeight.w600,
                  color: lowCount > 0 ? colors.warnText : colors.successText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: reducedMotion
                ? children[i]
                : _RiseIn(
                    delay: Duration(milliseconds: 60 * i),
                    duration: motion.entrance,
                    curve: motion.standardEasing,
                    child: children[i],
                  ),
          ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: Button(
                label: 'Save to vault',
                loading: saving,
                onPressed: onSave,
                expand: true,
              ),
            ),
            const SizedBox(width: 8),
            Button(
              label: 'Retake',
              kind: ButtonKind.quiet,
              onPressed: saving ? null : onRetake,
            ),
          ],
        ),
      ],
    );
  }
}

/// The MI-12 rise-in: 250ms translate-up + fade, staggered by [delay].
class _RiseIn extends StatefulWidget {
  const _RiseIn({
    required this.delay,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(parent: _controller, curve: widget.curve);
    _timer = Timer(widget.delay, () {
      if (mounted) unawaited(_controller.forward());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
