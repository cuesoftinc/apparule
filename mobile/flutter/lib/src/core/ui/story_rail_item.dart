import 'dart:async';
import 'dart:math' as math;

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/avatar.dart';
import 'package:flutter/material.dart';

/// The Figma `StoryRailItem` set's `state` axis (46:95).
enum StoryRailItemState { unseen, seen, loading }

/// StoryRailItem — the Figma `StoryRailItem` set (46:95); web sibling
/// `StoryRailItem.tsx`. States: unseen (gradient ring) / seen (gray) /
/// loading (dashed gradient ring rotating at 1.5s while the story
/// preloads, MI-8). Geometry ([Decided 2026-07-19]): 64px ring frame
/// wrapping a 56px photo — 2px stroke + 2px clear gap.
class StoryRailItem extends StatelessWidget {
  const StoryRailItem({
    required this.username,
    this.image,
    this.state = StoryRailItemState.unseen,
    this.onTap,
    super.key,
  });

  final String username;
  final ImageProvider<Object>? image;
  final StoryRailItemState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;

    final Widget ring;
    if (state == StoryRailItemState.loading) {
      ring = SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const Positioned.fill(child: _RotatingDashedRing()),
            Avatar(name: username, size: AvatarSize.s56, image: image),
          ],
        ),
      );
    } else {
      ring = Avatar(
        name: username,
        size: AvatarSize.s64,
        image: image,
        ring: state == StoryRailItemState.seen
            ? AvatarRing.gray
            : AvatarRing.gradient,
      );
    }

    return Semantics(
      // One node announcing the username once (ring + caption are visual).
      container: true,
      excludeSemantics: true,
      label: username,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ring,
              const SizedBox(height: 4),
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: typography.micro12.copyWith(color: colors.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The MI-8 loading affordance — a dashed accent-gradient circle (Figma
/// 46:88: 6/7 dash pattern, 2px stroke) rotating once per 1.5s; static
/// under reduced motion.
class _RotatingDashedRing extends StatefulWidget {
  const _RotatingDashedRing();

  @override
  State<_RotatingDashedRing> createState() => _RotatingDashedRingState();
}

class _RotatingDashedRingState extends State<_RotatingDashedRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        painter: _DashedRingPainter(gradient: colors.accentGradient),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.gradient});

  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - 2) / 2;
    // 6/7 dash pattern mapped to arc length.
    const dash = 6.0;
    const gap = 7.0;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dash + gap)).floor();
    final dashAngle = dash / radius;
    final stepAngle = 2 * math.pi / count;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * stepAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) =>
      oldDelegate.gradient != gradient;
}
