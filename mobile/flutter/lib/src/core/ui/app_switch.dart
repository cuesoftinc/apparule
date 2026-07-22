import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

/// Switch — the Figma `Switch` atom (§8.2b form primitives): `state: on /
/// off × enabled / disabled`. On paints the accent gradient track (the
/// B7-mobile canvas toggles, 207:2); off is a border-token track. 48×28
/// with a 24px knob — Material's Switch can't bind a gradient track, so
/// the atom draws its own chrome over the shared motion tokens.
/// Consumed by the B7 settings sub-screens.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;

  /// `null` renders the disabled state (40% opacity, taps ignored).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final motion = theme.extension<AppMotion>()!;

    final enabled = onChanged != null;
    Color dim(Color color) =>
        enabled ? color : color.withValues(alpha: color.a * 0.4);

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: motion.fast,
          curve: motion.standardEasing,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: value
                ? LinearGradient(
                    colors: colors.accentGradient.colors.map(dim).toList(),
                  )
                : null,
            color: value ? null : dim(colors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: AnimatedAlign(
            duration: motion.fast,
            curve: motion.standardEasing,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: dim(const Color(0xFFFFFFFF)),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
