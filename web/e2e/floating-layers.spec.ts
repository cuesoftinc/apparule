// Floating-layer collision canon (org SKILL.md, 2026-07-19): every
// popover/dropdown/menu/date-picker stays fully inside the viewport at
// every breakpoint and anchor position — found live as a period-picker
// popover clipping off the right screen edge on expendit. The registry
// Popover opens align="end" from a narrow trigger near the content edge,
// so unclamped it would escape the viewport: the canonical edge-anchored
// probe. /dev/components is served in dev and TEST_MODE builds (the e2e
// system under test).
import { expect, test, type Page } from "@playwright/test";

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

// ---------------------------------------------------------------------------
// C2 — a select opened from inside a Sheet/modal: the menu portals to the
// body (never clips into the sheet's inner scrollbox), stays height-capped
// and fully inside the viewport, and its bottom edge is really clickable.
// 700px is the short-viewport case that squeezes the menu.
// ---------------------------------------------------------------------------

async function expectMenuUnclipped(page: Page, height: number) {
  const menu = page.getByRole("listbox");
  await expect(menu).toBeVisible();
  const box = await menu.boundingBox();
  expect(box).not.toBeNull();
  expect(box!.y, "menu top inside viewport").toBeGreaterThanOrEqual(0);
  expect(
    box!.y + box!.height,
    "menu bottom inside viewport",
  ).toBeLessThanOrEqual(height);
  // 288px cap (max-h-72) + hairline borders.
  expect(box!.height).toBeLessThanOrEqual(290);
  // No clipping: the point just inside the menu's bottom edge hit-tests to
  // the menu itself, not an overlaying sheet or scrollbox.
  const hit = await page.evaluate(() => {
    const lb = document.querySelector('[role="listbox"]')!;
    const r = lb.getBoundingClientRect();
    const el = document.elementFromPoint(r.x + r.width / 2, r.bottom - 5);
    return lb.contains(el);
  });
  expect(hit, "menu bottom edge is hit-testable").toBe(true);
}

test("report-reason select inside the report sheet is unclipped at 1440×700", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 700 });
  await page.goto("/signin");
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
  await page.waitForSelector('[data-testid="feed-list"]');
  await page
    .getByTestId("post-card")
    .first()
    .getByRole("button", { name: "More options" })
    .click();
  await page.getByRole("menuitem", { name: "Report post" }).click();
  await page.getByLabel("Report reason").click();
  await expectMenuUnclipped(page, 700);
});
