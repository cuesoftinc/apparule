// Floating-layer collision canon (org SKILL.md, 2026-07-19): every
// popover/dropdown/menu/date-picker stays fully inside the viewport at
// every breakpoint and anchor position — found live as a period-picker
// popover clipping off the right screen edge on expendit. The registry
// Popover opens align="end" from a narrow trigger near the content edge,
// so unclamped it would escape the viewport: the canonical edge-anchored
// probe. /dev/components is served in dev and TEST_MODE builds (the e2e
// system under test).
import { expect, test } from "@playwright/test";

const VIEWPORTS = [
  { width: 1440, height: 900 },
  { width: 390, height: 844 },
];

for (const viewport of VIEWPORTS) {
  test(`edge-anchored popover stays fully inside the ${viewport.width}px viewport`, async ({
    page,
  }) => {
    await page.setViewportSize(viewport);
    await page.goto("/dev/components");

    await page.getByRole("button", { name: "Post overflow ⋯" }).click();
    const menu = page
      .getByRole("dialog")
      .filter({ has: page.getByRole("menuitem", { name: "Copy link" }) });
    await expect(menu).toBeVisible();

    const box = await menu.boundingBox();
    expect(box, "open popover has a bounding box").not.toBeNull();
    expect(box!.x, "left edge inside viewport").toBeGreaterThanOrEqual(0);
    expect(box!.y, "top edge inside viewport").toBeGreaterThanOrEqual(0);
    expect(
      box!.x + box!.width,
      "right edge inside viewport",
    ).toBeLessThanOrEqual(viewport.width);
    expect(
      box!.y + box!.height,
      "bottom edge inside viewport",
    ).toBeLessThanOrEqual(viewport.height);
  });
}
