import 'dart:async';

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// The Figma `Skeleton` set's `kind` axis (54:464).
enum SkeletonKind { line, avatar, media, card }

/// Skeleton — the Figma `Skeleton` set (54:464); web sibling
/// `Skeleton.tsx`. MI-19: 1.2s linear shimmer, an 8% white overlay sweep;
/// reduced motion renders the static block. `card` composes the PostCard
/// placeholder anatomy (52:288): header, square media, action circles,
/// caption lines.
class Skeleton extends StatelessWidget {
  const Skeleton({this.kind = SkeletonKind.line, super.key});

  final SkeletonKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radii = theme.extension<AppRadii>()!;

    switch (kind) {
      case SkeletonKind.line:
        return _Shimmer(
          height: 16,
          width: double.infinity,
          radius: radii.card,
        );
      case SkeletonKind.avatar:
        return _Shimmer(height: 44, width: 44, radius: radii.pill);
      case SkeletonKind.media:
        return const AspectRatio(
          aspectRatio: 1,
          child: _Shimmer(radius: 0),
        );
      case SkeletonKind.card:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
              child: Row(
                children: <Widget>[
                  _Shimmer(height: 32, width: 32, radius: radii.pill),
                  const SizedBox(width: 12),
                  _Shimmer(height: 12, width: 128, radius: radii.card),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const AspectRatio(aspectRatio: 1, child: _Shimmer(radius: 0)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 16 : 0),
                      child: _Shimmer(
                        height: 24,
                        width: 24,
                        radius: radii.pill,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Shimmer(height: 12, width: 96, radius: radii.card),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.75,
                    child: _Shimmer(height: 12, radius: radii.card),
                  ),
                  const SizedBox(height: 8),
                  _Shimmer(
                    height: 40,
                    width: double.infinity,
                    radius: radii.card,
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.radius, this.height, this.width});

  final double radius;
  final double? height;
  final double? width;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // MI-19: 1.2s linear sweep.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect prefers-reduced-motion: static block, no sweep.
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
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: SizedBox(
          height: widget.height,
          width: widget.width,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // The 8% white overlay sweeps left → right (MI-19).
                  begin: Alignment(2 * _controller.value - 2, 0),
                  end: Alignment(2 * _controller.value, 0),
                  colors: <Color>[
                    colors.border.withValues(alpha: 0.5),
                    Color.alphaBlend(
                      const Color(0x14FFFFFF),
                      colors.border.withValues(alpha: 0.5),
                    ),
                    colors.border.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
