import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The MI-10 stepper header spec (Figma 50:256): a full-bleed 4px progress
/// track and a centred "Step n of N · Label" caption.
@immutable
class SheetStepper {
  const SheetStepper({required this.steps, required this.current})
    : assert(steps.length > 0, 'steps must not be empty'),
      assert(
        current >= 0 && current < steps.length,
        'current must index into steps',
      );

  /// Ordered step labels (Measurements → Notes/Budget → Review).
  final List<String> steps;

  /// 0-based current step; the track fills `(current+1)/length`.
  final int current;
}

/// The Figma `size` axis: `default` (480px secondary-flow panel) / `wide`
/// (the 896px two-column post-detail panel). On phone widths both fill the
/// screen; the constraint matters on tablets.
enum SheetSize {
  /// The `default` variant (Dart keyword — value renamed).
  defaultSize(480),

  /// The `wide` variant.
  wide(896);

  const SheetSize(this.maxWidth);

  /// Panel width cap.
  final double maxWidth;
}

/// Sheet — the Figma `Sheet` set (50:296); web sibling `Sheet.tsx`. Axes:
/// `platform` mobile/desktop · `stepper` false/true · `size` default/wide.
/// The `platform` axis resolves to `mobile` by construction on Flutter
/// (the desktop variant is the web sibling's centred modal); C5 consumes
/// the `stepper: true` chrome. All secondary flows live in sheets
/// (design.md §3).
class Sheet extends StatelessWidget {
  const Sheet({
    required this.title,
    required this.child,
    this.stepper,
    this.size = SheetSize.defaultSize,
    this.onClose,
    super.key,
  });

  /// Centred 16px semibold header title.
  final String title;

  /// The `stepper` axis — non-null renders the MI-10 stepper header.
  final SheetStepper? stepper;

  final SheetSize size;

  /// Close handler — defaults to popping the enclosing route.
  final VoidCallback? onClose;

  /// Sheet body (scrolls inside the 85%-height cap).
  final Widget child;

  /// Presents [Sheet] as the modal bottom layer (z `sheet`, design.md §2)
  /// with the 50% barrier the Figma master specs.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    SheetStepper? stepper,
    SheetSize size = SheetSize.defaultSize,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x80000000),
      builder: (context) =>
          Sheet(title: title, stepper: stepper, size: size, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.maxWidth,
            maxHeight: maxHeight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radii.card),
            ),
            child: ColoredBox(
              color: colors.bgElev,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Figma master (50:296): mobile grabber — 36×4, 2px radius.
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: <Widget>[
                        // Leading spacer balances the close button so the
                        // title centres optically (web sibling geometry).
                        const SizedBox(width: 36, height: 36),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.body16SemiBold.copyWith(
                              color: colors.text,
                            ),
                          ),
                        ),
                        Semantics(
                          label: 'Close',
                          button: true,
                          child: InkResponse(
                            onTap: onClose ?? () => Navigator.of(context).pop(),
                            radius: 18,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Icon(
                                LucideIcons.x,
                                size: 24,
                                color: colors.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (stepper != null) _StepperHeader(stepper: stepper!),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperHeader extends StatelessWidget {
  const _StepperHeader({required this.stepper});

  final SheetStepper stepper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final motion = theme.extension<AppMotion>()!;
    final typography = theme.extension<AppTypography>()!;

    final fraction = (stepper.current + 1) / stepper.steps.length;

    return Column(
      children: <Widget>[
        SizedBox(
          height: 4,
          width: double.infinity,
          child: ColoredBox(
            color: colors.border,
            child: Align(
              alignment: Alignment.centerLeft,
              // MI-10: the fill animates to the new fraction (300ms ease).
              child: AnimatedFractionallySizedBox(
                duration: motion.slow,
                curve: motion.standardEasing,
                widthFactor: fraction,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: colors.accentGradient),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Step ${stepper.current + 1} of ${stepper.steps.length} · '
            '${stepper.steps[stepper.current]}',
            textAlign: TextAlign.center,
            style: typography.caption13.copyWith(color: colors.text2),
          ),
        ),
      ],
    );
  }
}
