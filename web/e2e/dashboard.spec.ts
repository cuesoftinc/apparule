// W3 dashboard journeys (design.md §8.4, web-implementation.md §7), run in
// TEST_MODE against the in-app mock server. Serial: the mock store is a
// module singleton shared by every test in this file — journeys build on
// the seeded narrative in order.
import { expect, test, type Page } from "@playwright/test";

test.describe.configure({ mode: "serial" });

// The store is dev-persistent — reseed so journeys start from the canonical
// narrative even when Playwright reuses a running dev server.
test.beforeAll(async ({ request }) => {
  const res = await request.post("/api/mock/v1/testing/reset");
  if (!res.ok()) throw new Error("mock store reset failed");
});

// One tiny valid JPEG — uploads must survive the next/image optimizer.
const TINY_JPEG = Buffer.from(
  "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==",
  "base64",
);

async function signIn(page: Page) {
  await page.goto("/signin");
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
}

test.use({ viewport: { width: 1440, height: 900 } });

test("semantic landmarks: every dashboard screen renders one <main> and the primary <nav>", async ({
  page,
}) => {
  await signIn(page);
  const routes = [
    "/dashboard",
    "/dashboard/explore",
    "/dashboard/orders",
    "/dashboard/orders/req-apr-1042",
    "/dashboard/vault",
    "/dashboard/create",
    "/dashboard/kiki.adeyemi",
    "/dashboard/amara.designs",
    "/dashboard/settings",
    "/dashboard/settings/notifications",
    "/dashboard/settings/privacy",
    "/dashboard/settings/account",
    "/dashboard/admin/moderation",
    "/dashboard/designer/onboarding",
    "/dashboard/earnings",
  ];
  for (const route of routes) {
    await page.goto(route);
    await expect(page.locator("main"), `${route} has one <main>`).toHaveCount(1);
    await expect(
      page.locator('nav[aria-label="Primary"]:visible'),
      `${route} shows the primary nav`,
    ).toHaveCount(1);
  }
});

// Runs BEFORE the B1 journey (serial file): the journey follows tunde,
// which grows the feed past the canonical 7-post seed this test paginates.
test("B1 MI-6: infinite scroll — failed page retries, skeleton ×2, caught-up", async ({
  page,
}) => {
  // First cursor request FAILS (transient network); subsequent ones are
  // slowed so the MI-6 skeletons are observable.
  let cursorCalls = 0;
  await page.route(
    (url) =>
      url.pathname.endsWith("/api/mock/v1/feed") &&
      url.searchParams.has("cursor"),
    async (route) => {
      cursorCalls += 1;
      if (cursorCalls === 1) {
        await route.abort("connectionfailed");
        return;
      }
      await new Promise((resolve) => setTimeout(resolve, 700));
      await route.continue();
    },
  );
  await signIn(page);

  const cards = page.getByTestId("feed-list").locator("> li");
  // First ranked page (MI-6 page size 4 over the 7-post seeded feed).
  await expect(cards).toHaveCount(4);

  // Walking toward the end crosses the 3-from-end observer → prefetch;
  // the aborted page surfaces the explicit retry control (PR #103) —
  // the feed must not silently stop at an incomplete page.
  await cards.last().scrollIntoViewIfNeeded();
  const retry = page.getByTestId("feed-load-more-retry");
  await expect(retry).toBeVisible();
  await expect(cards).toHaveCount(4);

  // Retry → skeleton ×2 while the page is in flight → cards append.
  await retry.click();
  await expect(page.getByTestId("feed-loading-more")).toBeVisible();
  await expect(cards).toHaveCount(7);
  await expect(page.getByTestId("feed-loading-more")).toHaveCount(0);

  // Cursor exhausted → the MI-6 caught-up divider.
  await cards.last().scrollIntoViewIfNeeded();
  await expect(page.getByText(/all caught up/i)).toBeVisible();
});

test("B1 journey: like/save/follow → request stepper → order → quote → pay → escrow-held → thread MI-17", async ({
  page,
  request,
}) => {
  await signIn(page);

  // Feed renders the followed designers' posts (seed narrative).
  const feed = page.getByTestId("feed-list");
  await expect(feed).toBeVisible();
  const firstCard = page.getByTestId("post-card").first();

  // MI-2 like (optimistic) + MI-3 save. exact: true — Playwright's default
  // substring matching would let "Like" match "Unlike".
  await firstCard.getByRole("button", { name: "Like", exact: true }).click();
  await expect(
    firstCard.getByRole("button", { name: "Unlike", exact: true }),
  ).toBeVisible();
  await firstCard.getByRole("button", { name: "Save", exact: true }).click();
  await expect(
    firstCard.getByRole("button", { name: "Remove from saved" }),
  ).toBeVisible();

  // MI-7 follow morph in the right-column suggestions (tunde is seeded).
  const suggestions = page.getByLabel("Suggested designers");
  await suggestions.getByRole("button", { name: "Follow" }).first().click();
  await expect(
    suggestions.getByRole("button", { name: "Following" }).first(),
  ).toBeVisible();

  // MI-10 request stepper on the aso-oke post (no open seeded order).
  const asoOke = page.getByTestId("post-card").filter({ hasText: "aso-oke" });
  await asoOke.getByRole("button", { name: "Request this outfit" }).click();
  await expect(page.getByTestId("stepper-step-1")).toBeVisible();
  await page.getByRole("button", { name: "Continue" }).click();
  // Step 2 delivery pre-fills from the most recent order.
  await expect(page.getByTestId("stepper-step-2")).toBeVisible();
  await expect(page.getByLabel("Recipient name")).toHaveValue(/Kiki/);
  await page.getByRole("button", { name: "Continue" }).click();
  await expect(page.getByTestId("stepper-step-3")).toBeVisible();
  await page.getByTestId("stepper-submit").click();

  // Success: confetti + View order → the order exists in the mock store.
  await expect(page.getByText("Request sent")).toBeVisible();
  await page.getByRole("link", { name: "View order" }).click();
  await page.waitForURL("**/dashboard/orders/*");
  const orderId = page.url().split("/").pop()!;
  await expect(page.getByText("Requested", { exact: true }).first()).toBeVisible();

  // Designer quotes via the mock actor seam (x-mock-actor honored in TEST_MODE).
  const quoteRes = await request.post(`/api/mock/v1/requests/${orderId}/quote`, {
    headers: { "x-mock-actor": "maisonbisi" },
    data: { quote_cents: 7_000_000, currency: "NGN", due_at: "2026-08-30" },
  });
  expect(quoteRes.status()).toBe(200);

  // Customer pays → escrow-held (MI-15).
  await page.reload();
  await page.getByRole("button", { name: /^Pay ₦/ }).click();
  // Both the PaymentBox headline and the timeline row carry the copy.
  await expect(page.getByText(/held in escrow/i).first()).toBeVisible();

  // MI-17: sending a message raises the typing pulse, then the scripted reply.
  await page.getByLabel(/Message maisonbisi/).fill("Can't wait!");
  await page.getByRole("button", { name: "Send" }).click();
  await expect(page.getByTestId("thread-typing")).toBeVisible();
  await expect(page.getByText(/reply properly shortly/)).toBeVisible({
    timeout: 5_000,
  });
});

test("B3: the seeded list covers all ten lifecycle states", async ({ page }) => {
  await signIn(page);
  await page.goto("/dashboard/orders");
  const list = page.getByTestId("orders-list");
  for (const label of [
    "Requested",
    "Quoted",
    "Paid",
    "In progress",
    "Shipped",
    "Delivered",
    "Refunded",
    "Declined",
    "Disputed",
    "Cancelled",
  ]) {
    await expect(
      list.getByText(label, { exact: true }).first(),
      `state pill ${label}`,
    ).toBeVisible();
  }
});

test("B2 explore: turnaround chip filters; near-me proximity-ranks without dropping posts", async ({
  page,
}) => {
  await signIn(page);
  await page.goto("/dashboard/explore");
  const tiles = page.getByLabel("Posts").locator("li");
  const tileImgs = page.getByLabel("Posts").locator("li img");

  // Default recency order leads with the newest post — the Abuja atelier.
  await expect(tileImgs.first()).toHaveAttribute("alt", /atelier/);
  const total = await tiles.count();

  // "Near me" (kiki is Lagos-based): every Lagos designer's post ranks
  // above the Abuja designer's; the Abuja post still renders — proximity
  // is a ranking, never a hard gate (pages.md B2).
  await page.getByRole("button", { name: "Near me" }).click();
  await expect(tileImgs.first()).not.toHaveAttribute("alt", /atelier/);
  await expect(tileImgs.last()).toHaveAttribute("alt", /atelier/);
  await expect(tiles).toHaveCount(total);
  await page.getByRole("button", { name: "Near me" }).click();

  // Turnaround "≤ 1 week" keeps only the 7-day posts (both tunde's).
  await page.getByRole("button", { name: "≤ 1 week" }).click();
  await expect(tiles).toHaveCount(2);
  await expect(tileImgs.first()).toHaveAttribute(
    "alt",
    "Two men in matching African print shirts",
  );
  await page.getByRole("button", { name: "≤ 1 week" }).click();
  await expect(tiles).toHaveCount(total);
});

test("B4 vault: webcam QC failure → retake → capture → save; history delete", async ({
  page,
}) => {
  await signIn(page);
  await page.goto("/dashboard/vault");
  await page.getByTestId("vault-retake").click();
  await page.getByRole("button", { name: /Use your camera/ }).click();

  // Designated QC fixture: a file name containing a capture-qc code.
  await page
    .getByTestId("capture-file")
    .setInputFiles({ name: "fixture-blurry.jpg", mimeType: "image/jpeg", buffer: TINY_JPEG });
  await expect(page.getByRole("alert")).toContainText("Hold steady and retake");
  await page.getByRole("button", { name: "Retake" }).click();

  // Happy path: processing constellation → results → save to vault.
  await page
    .getByTestId("capture-file")
    .setInputFiles({ name: "photo.jpg", mimeType: "image/jpeg", buffer: TINY_JPEG });
  await expect(page.getByTestId("capture-processing")).toBeVisible();
  await expect(page.getByRole("button", { name: "Save to vault" })).toBeVisible({
    timeout: 5_000,
  });
  await page.getByRole("button", { name: "Save to vault" }).click();
  await expect(page.getByText("Saved to your vault")).toBeVisible();
  await expect(page.getByTestId("vault-grid")).toContainText("Chest Girth");

  // History sheet: sessions list with delete (vault CRUD).
  await page.getByTestId("vault-grid").getByRole("button").first().click();
  const history = page.getByTestId("history-list");
  await expect(history).toBeVisible();

  // F2-9: per-session export hands the browser a real download.
  const csvDownload = page.waitForEvent("download");
  await history
    .getByRole("button", { name: "Export session as CSV" })
    .first()
    .click();
  expect((await csvDownload).suggestedFilename()).toMatch(
    /^apparule-session-\d{4}-\d{2}-\d{2}\.csv$/,
  );
  const pdfDownload = page.waitForEvent("download");
  await history
    .getByRole("button", { name: "Export session as PDF" })
    .first()
    .click();
  expect((await pdfDownload).suggestedFilename()).toMatch(/\.pdf$/);

  const before = await history.locator("li").count();
  await history.getByRole("button", { name: "Delete session" }).first().click();
  await expect(history.locator("li")).toHaveCount(before - 1);
});

test("B5/B8: creator upsell → onboarding with Paystack resolution states → publish → profile grid", async ({
  page,
}) => {
  await signIn(page);

  // Non-creator sees the upsell (B5).
  await page.goto("/dashboard/create");
  await page.getByTestId("become-designer").click();
  await page.waitForURL("**/dashboard/designer/onboarding");

  // Intro (what you get) → profile screen (Figma 269:10178): username claim
  // pre-filled + display name + bio.
  await page.getByTestId("onboarding-start").click();
  await expect(page.getByLabel("Username")).toHaveValue("kiki.adeyemi");
  await page.getByLabel("Display name").fill("Kiki Ade Studio");
  await page.getByLabel("Bio").fill("Statement pieces, made to measure.");
  await page.getByTestId("onboarding-create-profile").click();

  // Banking: mismatch fixture (00…) → error; then resolved-name confirm.
  await page.getByRole("combobox", { name: "Bank" }).click();
  await page.getByRole("option", { name: "GTBank" }).click();
  await page.getByTestId("account-number").fill("0012345678");
  await page.getByTestId("resolve-account").click();
  await expect(page.getByText(/Could not resolve/)).toBeVisible();
  await page.getByTestId("account-number").fill("0123456789");
  await page.getByTestId("resolve-account").click();
  await expect(page.getByTestId("resolved-name")).toContainText("KIKI ADEYEMI");
  await page.getByTestId("confirm-account").click();
  await expect(page.getByTestId("onboarding-done")).toBeVisible();

  // Composer unlocks (auth context refreshed) → publish to the feed store.
  await page.getByRole("link", { name: "Post your first outfit" }).click();
  await page.waitForURL("**/dashboard/create");
  await page
    .getByTestId("media-input")
    .setInputFiles({ name: "look.jpg", mimeType: "image/jpeg", buffer: TINY_JPEG });
  await expect(page.getByTestId("composer-tiles")).toBeVisible();
  await page.getByLabel("Caption").fill("First drop — ankara wrap dress.");
  await expect(page.getByTestId("composer-publish")).toBeEnabled();
  await page.getByTestId("composer-publish").click();
  await expect(page.getByText("Outfit published")).toBeVisible();
  await page.waitForURL("**/dashboard");

  // The post lands on the designer's own B6 grid.
  await page.goto("/dashboard/kiki.adeyemi");
  await expect(page.getByTestId("profile-grid").locator("li")).toHaveCount(1);
});

test("B7: notification prefs persist across reload; consent history renders", async ({
  page,
}) => {
  await signIn(page);
  await page.goto("/dashboard/settings/notifications");
  const quotes = page.getByRole("switch", { name: "Quotes" });
  await expect(quotes).toHaveAttribute("aria-checked", "true");
  await quotes.click();
  await expect(quotes).toHaveAttribute("aria-checked", "false");
  await page.reload();
  await expect(page.getByRole("switch", { name: "Quotes" })).toHaveAttribute(
    "aria-checked",
    "false",
  );

  await page.goto("/dashboard/settings/privacy");
  await expect(page.getByTestId("consent-history")).toContainText(
    "Terms of Service",
  );
});

test("B7a: staff moderation queue — dismiss clears the report", async ({
  page,
}) => {
  await signIn(page);
  await page.goto("/dashboard/admin/moderation");
  const queue = page.getByTestId("moderation-queue");
  await expect(queue).toContainText("Buy followers cheap");
  await queue.getByRole("button", { name: "Dismiss" }).click();
  await expect(page.getByText(/queue is clear/)).toBeVisible();
});

test("B3 matrix: customer dispute freezes payout; confirm-delivery releases it", async ({
  page,
}) => {
  await signIn(page);

  // Dispute from paid (order-lifecycle §1).
  await page.goto("/dashboard/orders/req-apr-1036");
  await page.getByRole("button", { name: "Something wrong?" }).click();
  await page.getByRole("combobox", { name: "Dispute reason" }).click();
  await page.getByRole("option", { name: "Size is wrong" }).click();
  await page.getByRole("dialog").getByRole("button", { name: "Open dispute" }).click();
  await expect(page.getByText("Disputed", { exact: true }).first()).toBeVisible();
  await expect(page.getByText(/frozen/i).first()).toBeVisible();

  // Confirm delivery from shipped → payout released.
  await page.goto("/dashboard/orders/req-apr-1044");
  await page.getByTestId("confirm-delivery").click();
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Confirm delivery" })
    .click();
  await expect(page.getByText("Delivered", { exact: true }).first()).toBeVisible();
});

test("designer side (actor seam): decline with reason; earnings itemize the released payout", async ({
  page,
}) => {
  // The QA actor seam — the mock signs this session in as tunde.o.
  await page.addInitScript(() => {
    window.sessionStorage.setItem("apparule.testmode.actor", "tunde.o");
  });
  await signIn(page);

  await page.goto("/dashboard/orders");
  await page.getByRole("tab", { name: "As designer" }).click();
  const list = page.getByTestId("orders-list");
  await list.getByRole("button", { name: "Open order APR-1031" }).click();
  await page.waitForURL("**/dashboard/orders/req-apr-1031");

  // Decline-with-reason sheet (reason required, flows/designer.md §2).
  await page.getByRole("button", { name: "Decline" }).click();
  await page.getByRole("combobox", { name: "Decline reason" }).click();
  await page.getByRole("option", { name: "Fully booked right now" }).click();
  await page.getByRole("dialog").getByRole("button", { name: "Decline" }).click();
  await expect(page.getByText("Declined", { exact: true }).first()).toBeVisible();

  // B9: the payout released by the previous test itemizes for tunde.
  await page.goto("/dashboard/earnings");
  await expect(page.getByText("₦19,800").first()).toBeVisible();
  await expect(page.getByTestId("transactions-list")).toContainText("APR-1044");
  await expect(page.getByTestId("payout-status-chip")).toBeVisible();
});

test("designer quote via the UI: the due-date calendar works inside the quote sheet", async ({
  page,
  request,
}) => {
  // Regression: the DateInput popover sat on the z-20 dropdown layer under
  // the z-40 quote Sheet, so the calendar swallowed no clicks and a quote
  // could never be sent from the UI. Close the seeded open order on this
  // post first (no-op 409 when an earlier test already delivered it), then
  // file a fresh request as kiki via the API.
  const close = await request.post("/api/mock/v1/requests/req-apr-1044/confirm-delivery", {
    headers: { "x-mock-actor": "kiki.adeyemi" },
  });
  expect([200, 409]).toContain(close.status());
  const res = await request.post("/api/mock/v1/posts/post-print-brothers/requests", {
    headers: { "x-mock-actor": "kiki.adeyemi" },
    data: {
      session_id: "sess-recent-scan",
      notes: "Quote regression fixture",
      delivery: {
        recipient_name: "Kiki Adeyemi",
        phone: "+2348012345678",
        line1: "14 Adeola Odeku St",
        city: "Lagos",
        state: "Lagos",
        country: "NG",
      },
    },
  });
  expect(res.status()).toBe(201);
  const order = await res.json();

  await page.addInitScript(() => {
    window.sessionStorage.setItem("apparule.testmode.actor", "tunde.o");
  });
  await signIn(page);
  await page.goto(`/dashboard/orders/${order.id}`);

  await page.getByRole("button", { name: "Send quote" }).click();
  const sheet = page.getByRole("dialog");
  await sheet.getByLabel("Quote amount").fill("58000");
  await sheet.getByLabel("Due date").click();
  const picker = page.getByTestId("date-picker");
  await expect(picker).toBeVisible();
  // the calendar must actually receive the click (the z-layer regression)
  await picker.getByRole("button", { name: "Next month" }).click();
  await picker
    .getByRole("button", { name: "15", exact: true })
    .first()
    .click();
  await sheet.getByRole("button", { name: "Send quote" }).click();

  await expect(page.getByText("Quoted", { exact: true }).first()).toBeVisible();
  await expect(page.getByText(/₦58,000/).first()).toBeVisible();
});

// The 390 overflow sweep moved to e2e/mobile-responsive.spec.ts (P1
// mobile pass): every route, 390 + 768, plus wide-element containment.
