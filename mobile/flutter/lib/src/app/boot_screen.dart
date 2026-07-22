import 'dart:async';

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// How long the silent restore may run before the boot frame admits a
/// progress affordance (boot-flow directive 2026-07-22: no spinners
/// unless restore exceeds ~300ms — over fakes it resolves in
/// milliseconds, so the spinner is a slow-network Firebase contingency).
const Duration kBootSpinnerDelay = Duration(milliseconds: 300);

/// The in-app boot state — the frame between the native splash and the
/// router while the silent session restore runs (mobile-implementation.md
/// §9; boot-flow directive 2026-07-22). A minimal branded surface: the
/// gradient wordmark centered on the token background — the same brand
/// construction as the native splash and C1, so cold start reads as one
/// continuous surface and a signed-out boot never flashes C1 chrome.
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  Timer? _spinnerTimer;
  bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
    _spinnerTimer = Timer(kBootSpinnerDelay, () {
      setState(() => _showSpinner = true);
    });
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final spacing = theme.extension<AppSpacing>()!;
    final typography = theme.extension<AppTypography>()!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // The C1 wordmark construction (design.md §2 accent gradient,
            // the one gradient role) — brand continuity from splash to
            // sign-in.
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: <Color>[colors.accentStart, colors.accentEnd],
              ).createShader(bounds),
              child: Text(
                context.l10n.appTitle,
                style: typography.display32Bold.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: spacing.s8),
            // Reserved slot: the wordmark must not shift when the spinner
            // arrives.
            SizedBox.square(
              dimension: 20,
              child: _showSpinner
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.text2,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
