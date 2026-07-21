// axe gate for the marketing home (2026-07-21 a11y audit): the decorative
// MiniScreen phone/dashboard mocks compose real, focusable component
// instances under aria-hidden — without the real `inert` attribute they
// shipped 8 serious axe `aria-hidden-focus` violations (keyboard focus
// landing inside invisible mock UI). The gate pins the class at zero: no
// critical violations, and specifically no aria-hidden-focus, ever again.
// (Serious-level light-theme color-contrast is token work tracked
// separately — not gated here.)
import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("home has zero critical axe violations and zero aria-hidden-focus", async ({
  page,
}) => {
  await page.goto("/");
  // Hero mock rendered — the surface the ×8 finding came from.
  await expect(page.getByTestId("hero-phone")).toBeVisible();

  const results = await new AxeBuilder({ page }).analyze();
  const critical = results.violations.filter(
    (violation) => violation.impact === "critical",
  );
  expect(
    critical.map((violation) => `${violation.id} ×${violation.nodes.length}`),
  ).toEqual([]);
  expect(
    results.violations.find(
      (violation) => violation.id === "aria-hidden-focus",
    ),
  ).toBeUndefined();
});
