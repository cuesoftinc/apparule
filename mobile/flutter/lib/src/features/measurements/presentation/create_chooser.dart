import 'dart:async';

import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/ui/choice_card.dart';
import 'package:apparule/src/core/ui/sheet.dart';
import 'package:apparule/src/features/measurements/presentation/capture_launcher.dart';
import 'package:apparule/src/features/profile/presentation/profile_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The ➕ tab's unified create chooser (M-11, canvas 548:2725): a
/// two-option Sheet on the C1b choice-card language — "Take measurements"
/// (primary, accent border) hands off to the capture entry gesture
/// (guide on first run, camera once the persisted flag is set), "Post an
/// outfit" is designer-gated: designers see the fit-data subtitle and
/// route to the C15 composer; non-designers route to C13
/// become-a-designer ("Become a designer to post").
Future<void> showCreateChooser(BuildContext context) {
  return Sheet.show<void>(
    context,
    title: context.l10n.createChooserTitle,
    child: const _CreateChooserBody(),
  );
}

class _CreateChooserBody extends ConsumerWidget {
  const _CreateChooserBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The designer state flips the Post-an-outfit subtitle (M-11);
    // profileViewModel derives it from the earnings repository.
    final designer =
        ref.watch(profileViewModelProvider).value?.designerEnabled ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ChoiceCard(
            icon: LucideIcons.camera,
            title: l10n.createChooserMeasureTitle,
            subtitle: l10n.createChooserMeasureMeta,
            primary: true,
            onTap: () {
              Navigator.of(context).pop();
              // The guide-first-run branch lives in the shared launcher.
              unawaited(launchCaptureFlow(context, ref));
            },
          ),
          const SizedBox(height: 12),
          ChoiceCard(
            icon: LucideIcons.shirt,
            title: l10n.createChooserPostTitle,
            subtitle: designer
                ? l10n.createChooserPostMetaDesigner
                : l10n.createChooserPostMetaNonDesigner,
            onTap: () {
              Navigator.of(context).pop();
              // Designer-gated (M-11): designers compose (C15),
              // everyone else lands on become-a-designer (C13).
              unawaited(
                designer
                    ? const ComposerRoute().push<void>(context)
                    : const DesignerOnboardingRoute().push<void>(context),
              );
            },
          ),
        ],
      ),
    );
  }
}
