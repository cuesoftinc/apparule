import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The notched-device contract every screen suite asserts against
/// (mobile-implementation.md §7): CI's default test view has NO display
/// cutout, so a screen can paint into the status-bar region and still
/// pass every test and golden — exactly the live-simulator defect this
/// helper exists to catch (headers under the iPhone 17 Pro Dynamic
/// Island, 2026-07-22).
///
/// [applyNotchedView] shapes the test view like that device — a 59px top
/// inset and the 34px home-indicator band — and
/// [expectNoContentInTopInset] then fails if any text, icon or tappable
/// renders inside the top inset. Chrome may PAINT there (the bar
/// background and the C6 over-media scrim deliberately extend behind the
/// status bar); content may not.

/// iPhone 17 Pro top inset in logical px (status bar / Dynamic Island).
const double kNotchTopInset = 59;

/// iPhone 17 Pro bottom home-indicator inset in logical px.
const double kNotchBottomInset = 34;

/// Reshapes the test view with notched-device insets at dpr 1.
///
/// [size] keeps the suites' tall-canvas convention (real device width,
/// generous height) so layouts that fit today still fit with the insets
/// applied — the assertion under test is inset placement, not viewport
/// crunch.
void applyNotchedView(
  WidgetTester tester, {
  Size size = const Size(402, 1600),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  const insets = FakeViewPadding(
    top: kNotchTopInset,
    bottom: kNotchBottomInset,
  );
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  addTearDown(tester.view.reset);
}

/// Asserts no interactive or textual content renders inside the top
/// inset band: every visible [RichText] (Text and Icon both render
/// through it) and every tappable ([InkResponse]/[GestureDetector] with
/// a tap handler) must sit at or below [inset].
void expectNoContentInTopInset(
  WidgetTester tester, {
  double inset = kNotchTopInset,
}) {
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final band = Rect.fromLTWH(0, 0, width, inset);

  final candidates = find.byWidgetPredicate(
    (widget) =>
        widget is RichText ||
        (widget is InkResponse && widget.onTap != null) ||
        (widget is GestureDetector && widget.onTap != null),
    description: 'text, icons, and tappables',
  );

  final offenders = <String>[];
  for (final element in candidates.evaluate()) {
    final renderObject = element.renderObject;
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize ||
        renderObject.size.isEmpty) {
      continue;
    }
    final rect = MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      Offset.zero & renderObject.size,
    );
    if (rect.isEmpty || !rect.overlaps(band)) continue;
    offenders.add('${element.widget.runtimeType} at $rect');
  }

  expect(
    offenders,
    isEmpty,
    reason:
        'Content must clear the ${inset}px top inset (notch); '
        'found: ${offenders.join(', ')}',
  );
}
