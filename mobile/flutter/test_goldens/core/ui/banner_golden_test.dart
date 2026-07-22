import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/banner.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_themes.dart';

/// Banner (Figma 95:1220) — `tone` ×4 · `dismiss` persistent/dismissable
/// (+ the action-link slot), both themes.
void main() {
  themedGoldenTest(
    'Banner matrix',
    fileName: 'banner',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        for (final tone in BannerTone.values) ...<Widget>[
          GoldenTestScenario(
            name: '${tone.name} · persistent',
            child: SizedBox(
              width: 390,
              child: AppBanner(
                tone: tone,
                message:
                    'Your measurements are 47 days old — consider '
                    'refreshing before you order.',
              ),
            ),
          ),
          GoldenTestScenario(
            name: '${tone.name} · dismissable + action',
            child: SizedBox(
              width: 390,
              child: AppBanner(
                tone: tone,
                dismissable: true,
                actionLabel: 'Re-verify',
                onAction: () {},
                message: 'Payout verification lapsed.',
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
