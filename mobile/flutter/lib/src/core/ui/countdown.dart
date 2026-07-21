import 'package:flutter/material.dart';

/// Shared m:ss countdown text driven by an [Animation] of remaining seconds.
///
/// Salvaged from the legacy capture flow (mobile-implementation.md §11 KEEP —
/// the one legacy widget carried live); reused as the C6 3-2-1 capture
/// countdown. Touched only to satisfy the analyzer gates — behavior is
/// unchanged.
class Countdown extends AnimatedWidget {
  const Countdown({required this.animation, super.key})
    : super(listenable: animation);

  final Animation<int> animation;

  @override
  Widget build(BuildContext context) {
    final clock = Duration(seconds: animation.value);
    final minutes = clock.inMinutes.remainder(60);
    final seconds = clock.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        fontSize: 18,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
