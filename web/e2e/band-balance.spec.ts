// C3 — dashboard two-column band balance (cross-check pass, 2026-07-20):
// the B1 feed band renders the frame's exact column geometry (176:72 —
// 630px feed · 48px gutter · 320px meta rail), and the order-detail band
// (179:536) keeps the thread panel spanning the band beside the order
// content instead of hugging a short thread and leaving the band
// bottom-heavy. Runs in TEST_MODE against the mock server; read-only.
import { expect, test, type Page } from "@playwright/test";

async function signIn(page: Page) {
  await page.goto("/signin");
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
}

test.use({ viewport: { width: 1440, height: 900 } });

test("B1 feed band matches the 176:72 frame: 630px feed · 48px gutter · 320px rail", async ({
  page,
}) => {
  await signIn(page);
  await page.waitForSelector('[data-testid="feed-list"]');
  const feed = await page.getByTestId("feed-list").boundingBox();
  const rail = await page
    .getByLabel("Your measurements and suggestions")
    .boundingBox();
  expect(feed).not.toBeNull();
  expect(rail).not.toBeNull();

  expect(
    Math.abs(feed!.width - 630),
    "feed column is 630px",
  ).toBeLessThanOrEqual(2);
  expect(Math.abs(rail!.width - 320), "meta rail is 320px").toBeLessThanOrEqual(
    2,
  );
  const gutter = rail!.x - (feed!.x + feed!.width);
  expect(Math.abs(gutter - 48), "gutter is 48px").toBeLessThanOrEqual(2);
});

test("order-detail band: the thread panel fills the band beside the order content (no hugged short card)", async ({
  page,
}) => {
  await signIn(page);
  // #APR-1058 — seeded delivered order with a short two-message thread:
  // exactly the case that used to hug and leave ~576px of dead band.
  await page.goto("/dashboard/orders/req-apr-1058");
  await page.waitForSelector('[data-testid="order-thread"]');
  const left = await page.locator("main .grid > div").first().boundingBox();
  const card = await page.getByTestId("order-thread-panel").boundingBox();
  expect(left).not.toBeNull();
  expect(card).not.toBeNull();

  // Tops align across the band.
  expect(Math.abs(card!.y - left!.y), "columns top-align").toBeLessThanOrEqual(
    2,
  );
  // The card stretches to the band height, capped at 70vh (frame 179:536
  // shows the panel spanning ~60% of the 1024 frame with the composer
  // pinned to its bottom edge).
  const expected = Math.min(left!.height, 0.7 * 900);
  expect(
    Math.abs(card!.height - expected),
    "thread panel fills the band up to the 70vh cap",
  ).toBeLessThanOrEqual(2);

  // The composer pins to the panel's bottom edge (frame: input row on the
  // panel's bottom padding), not directly under the last bubble.
  const composer = await page.getByLabel(/^Message /).boundingBox();
  expect(composer).not.toBeNull();
  expect(
    card!.y + card!.height - (composer!.y + composer!.height),
    "composer hugs the panel bottom",
  ).toBeLessThanOrEqual(32);
});
