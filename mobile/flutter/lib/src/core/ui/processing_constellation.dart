import 'dart:async';

import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The Figma `ProcessingConstellation` set's `state` axis (64:748).
enum ProcessingState { processing, success, failed }

/// ProcessingConstellation — the Figma `ProcessingConstellation` set
/// (64:748); web sibling `ProcessingConstellation.tsx`. The "AI is
/// working" moment (MI-12): the MediaPipe-pose landmark constellation
/// animates over the captured photo while processing; success/failed
/// freeze it and swap the status line. The constellation strokes the
/// accent in every state.
class ProcessingConstellation extends StatelessWidget {
  const ProcessingConstellation({required this.state, this.image, super.key});

  final ProcessingState state;

  /// The captured photo the constellation draws over.
  final ImageProvider<Object>? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final (IconData? icon, Color statusColor, String status) = switch (state) {
      ProcessingState.processing => (null, colors.text2, 'Measuring…'),
      ProcessingState.success => (
        LucideIcons.check,
        colors.success,
        'Done',
      ),
      ProcessingState.failed => (
        LucideIcons.x,
        colors.error,
        "Couldn't measure — retake",
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(radii.card),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const ColoredBox(color: Color(0xFF000000)),
                if (image != null)
                  // Paint-level opacity (not an Opacity layer) so the dim
                  // survives alchemist's blocked-text golden pass.
                  Image(
                    image: image!,
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation<double>(0.6),
                  ),
                Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.85,
                    child: AspectRatio(
                      aspectRatio: 200 / 300,
                      child: _Constellation(
                        pulsing: state == ProcessingState.processing,
                        color: colors.accentStart,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(icon, size: 14, color: statusColor),
                ),
              Flexible(
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: typography.caption13.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simplified MediaPipe-pose landmark set (nose, shoulders, elbows,
/// wrists, hips, knees, ankles) in the 200×300 guide space — the web
/// sibling's constant table.
const List<Offset> _landmarks = <Offset>[
  Offset(100, 40), // nose
  Offset(72, 88), Offset(128, 88), // shoulders
  Offset(56, 130), Offset(144, 130), // elbows
  Offset(48, 170), Offset(152, 170), // wrists
  Offset(82, 164), Offset(118, 164), // hips
  Offset(78, 222), Offset(122, 222), // knees
  Offset(74, 280), Offset(126, 280), // ankles
];

const List<(int, int)> _segments = <(int, int)>[
  (0, 1), (0, 2), (1, 2), // head → shoulders
  (1, 3), (3, 5), (2, 4), (4, 6), // arms
  (1, 7), (2, 8), (7, 8), // torso
  (7, 9), (9, 11), (8, 10), (10, 12), // legs
];

/// MI-12: landmarks pulse in a 1.2s staggered wave (90ms apart) while
/// processing; reduced motion (and success/failed) render them static.
class _Constellation extends StatefulWidget {
  const _Constellation({required this.pulsing, required this.color});

  final bool pulsing;
  final Color color;

  @override
  State<_Constellation> createState() => _ConstellationState();
}

class _ConstellationState extends State<_Constellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_Constellation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final animate = widget.pulsing && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      unawaited(_controller.repeat());
    } else if (!animate) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _ConstellationPainter(
          color: widget.color,
          phase: widget.pulsing ? _controller.value : null,
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({required this.color, this.phase});

  final Color color;

  /// 0–1 wave phase while processing; `null` renders static dots.
  final double? phase;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 200;
    final scaleY = size.height / 300;
    canvas.scale(scaleX, scaleY);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5 / scaleX;
    for (final (a, b) in _segments) {
      canvas.drawLine(_landmarks[a], _landmarks[b], linePaint);
    }

    for (var i = 0; i < _landmarks.length; i++) {
      // Stagger: each landmark trails the wave by 90ms of the 1.2s cycle.
      var alpha = 1.0;
      if (phase != null) {
        final local = (phase! - i * (0.09 / 1.2)) % 1.0;
        alpha = 0.4 + 0.6 * (1 - (local - 0.5).abs() * 2).clamp(0.0, 1.0);
      }
      canvas.drawCircle(
        _landmarks[i],
        4 / scaleX,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.phase != phase;
}
