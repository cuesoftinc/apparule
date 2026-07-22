import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/golden_themes.dart';

/// Notched-device top chrome — ONE golden per shell chrome kind (root
/// bar, sub bar, immersive over-media), each under an iPhone 17
/// Pro-shaped 59px top inset: the bar surface (or scrim) extends up
/// behind the status bar while the 56px content row insets below it.
/// The widget suites assert the geometry on every screen
/// (`expectNoContentInTopInset`); these goldens pin what that inset
/// handling LOOKS like, once per chrome kind, instead of duplicating
/// every screen golden in a notched variant.
void main() {
  const inset = 59.0;

  Widget notched(Widget child) => MediaQuery(
    data: const MediaQueryData(
      size: Size(390, 200),
      padding: EdgeInsets.only(top: inset),
      viewPadding: EdgeInsets.only(top: inset),
    ),
    child: SizedBox(width: 390, height: 200, child: child),
  );

  themedGoldenTest(
    'Notched top chrome per shell kind',
    fileName: 'notched_chrome',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'root bar — surface behind the notch, wordmark below it',
          child: notched(
            Scaffold(
              appBar: AppTopBar(
                title: 'Apparule',
                trailing: const Icon(LucideIcons.bell, size: 24),
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'sub bar — back + title clear of the notch',
          child: notched(
            Scaffold(
              appBar: AppTopBar(
                kind: AppTopBarKind.sub,
                title: 'Settings',
                onBack: () {},
              ),
              body: const SizedBox.expand(),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'immersive — full-bleed media, scrim into the notch, '
              'chrome content below it',
          child: notched(
            Scaffold(
              backgroundColor: const Color(0xFF000000),
              extendBodyBehindAppBar: true,
              appBar: AppTopBar(
                kind: AppTopBarKind.overMedia,
                onBack: () {},
                trailing: const Icon(LucideIcons.flaskConical, size: 20),
              ),
              body: const ColoredBox(
                color: Color(0xFF444444),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
