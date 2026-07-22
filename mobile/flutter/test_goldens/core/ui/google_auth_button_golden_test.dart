import 'package:alchemist/alchemist.dart';
import 'package:apparule/src/core/ui/google_auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_themes.dart';

/// GoogleAuthButton (Figma 83:887) — `state`
/// default/pressed/loading/disabled, both themes.
void main() {
  themedGoldenTest(
    'GoogleAuthButton states',
    fileName: 'google_auth_button',
    // The loading cell hosts a spinner — never settles.
    pumpBeforeTest: pumpFrame,
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'default',
          child: SizedBox(
            width: 320,
            child: GoogleAuthButton(
              label: 'Continue with Google',
              onPressed: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'loading',
          child: SizedBox(
            width: 320,
            child: GoogleAuthButton(
              label: 'Continue with Google',
              loading: true,
              onPressed: () {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: const SizedBox(
            width: 320,
            child: GoogleAuthButton(
              label: 'Continue with Google',
              onPressed: null,
            ),
          ),
        ),
      ],
    ),
  );

  themedGoldenTest(
    'GoogleAuthButton pressed',
    fileName: 'google_auth_button_pressed',
    whilePerforming: press(find.byType(GoogleAuthButton)),
    builder: () => GoldenTestGroup(
      columns: 1,
      children: <Widget>[
        GoldenTestScenario(
          name: 'pressed',
          child: SizedBox(
            width: 320,
            child: GoogleAuthButton(
              label: 'Continue with Google',
              onPressed: () {},
            ),
          ),
        ),
      ],
    ),
  );
}
