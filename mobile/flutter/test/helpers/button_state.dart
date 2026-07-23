import 'package:apparule/src/core/ui/button.dart';
import 'package:flutter_test/flutter_test.dart';

/// True when the labelled DS [Button] is tappable — the CLASS 5 arming
/// checks read this to prove a destructive confirm is born DISARMED and
/// arms only after a deliberate pick. Pass [within] when the label also
/// exists outside the surface under test (a sheet over its trigger row).
bool buttonEnabled(WidgetTester tester, String label, {Finder? within}) {
  final text = within == null
      ? find.text(label)
      : find.descendant(of: within, matching: find.text(label));
  final button = tester.widget<Button>(
    find.ancestor(of: text, matching: find.byType(Button)).first,
  );
  return button.onPressed != null && !button.loading;
}
