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
    await expect(page.locator("main"), `${route} has one <main>`).toHaveCount(
      1,
    );
    await expect(
      // Prefix match: rail labels are distinct per instance
      // ("Primary" / "Primary, compact" — landmark rules).
      page.locator('nav[aria-label^="Primary"]:visible'),
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
  await expect(
    page.getByText("Requested", { exact: true }).first(),
  ).toBeVisible();

  // Designer quotes via the mock actor seam (x-mock-actor honored in TEST_MODE).
  const quoteRes = await request.post(
    `/api/mock/v1/requests/${orderId}/quote`,
    {
      headers: { "x-mock-actor": "maisonbisi" },
      data: { quote_cents: 7_000_000, currency: "NGN", due_at: "2026-08-30" },
    },
  );
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
  // B3 frame: every delivered bubble carries its send time beneath it
  // ("14:05" today, dated when older).
  await expect(
    page.getByTestId("order-thread").locator("time").first(),
  ).toBeVisible();
});

test("entity-nav: feed author links + detail header + comment authors navigate to profiles", async ({
  page,
}) => {
  await signIn(page);

  // B1 feed card: the header avatar+username is a real anchor to the
  // designer profile (the web sibling of the mobile PostCard author bug).
  const firstAuthor = page.getByTestId("post-author-link").first();
  const href = await firstAuthor.getAttribute("href");
  expect(href).toMatch(/^\/dashboard\/[a-z0-9._]+$/);
  await firstAuthor.click();
  await page.waitForURL(`**${href}`);
  await expect(page.getByRole("heading", { level: 1 })).toContainText(
    href!.split("/").pop()!,
  );

  // Post detail: header link wraps the avatar too (no dead zone), and
  // comment rows carry author links.
  await page.goBack();
  await page
    .getByRole("button", { name: /View all \d+ comments/ })
    .first()
    .click();
  const detailAuthor = page.getByTestId("detail-author-link");
  await expect(detailAuthor).toBeVisible();
  expect(await detailAuthor.getAttribute("href")).toMatch(/^\/dashboard\//);
  await expect(detailAuthor.locator("span").last()).toBeVisible(); // username inside the link
  const commentAvatar = page.getByTestId("comment-author-avatar").first();
  await expect(commentAvatar).toBeVisible();
  expect(await commentAvatar.getAttribute("href")).toMatch(/^\/dashboard\//);
});

test("B3: the seeded list covers all ten lifecycle states", async ({
  page,
}) => {
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

test("B4 vault: two-photo upload — per-pose QC failure → re-pick side only → save; history delete", async ({
  page,
}) => {
  await signIn(page);
  await page.goto("/dashboard/vault");
  await page.getByTestId("vault-retake").click();
  await page.getByRole("button", { name: /Upload photos/ }).click();

  // The upload view (M-12, Figma 549:2): two labeled dropzones + height +
  // the mobile-app hint line.
  const uploadView = page.getByTestId("upload-measurements");
  await expect(uploadView).toBeVisible();
  await expect(uploadView).toContainText(
    "Best experience: guided capture on the Apparule app",
  );

  // Height prefills from the latest capture session (seed: 168) — never a
  // fabricated default.
  const height = page.getByLabel("Height in centimeters");
  await expect(height).toHaveValue("168");
  await height.fill("170");

  // Front passes; the side file is a designated QC fixture (a file name
  // containing a capture-qc code — per-pose QC, M-10).
  await page.getByTestId("capture-file-front").setInputFiles({
    name: "front.jpg",
    mimeType: "image/jpeg",
    buffer: TINY_JPEG,
  });
  await page.getByTestId("capture-file-side").setInputFiles({
    name: "fixture-blurry.jpg",
    mimeType: "image/jpeg",
    buffer: TINY_JPEG,
  });
  await page.getByTestId("get-measurements").click();

  // The 422 names the failing pose: only the side dropzone re-opens, the
  // accepted front pose keeps its thumbnail (pose 1 is never discarded).
  await expect(page.getByTestId("pose-error-side")).toBeVisible();
  await expect(uploadView.getByRole("status")).toContainText(
    "Hold steady and retake",
  );
  await expect(uploadView).toContainText("front.jpg · uploaded");

  // Re-pick the failing pose only → processing constellation → results.
  await page.getByTestId("capture-file-side").setInputFiles({
    name: "side.jpg",
    mimeType: "image/jpeg",
    buffer: TINY_JPEG,
  });
  await expect(page.getByTestId("pose-error-side")).toHaveCount(0);
  await page.getByTestId("get-measurements").click();
  await expect(page.getByTestId("capture-processing")).toBeVisible();
  await expect(page.getByRole("button", { name: "Save to vault" })).toBeVisible(
    {
      timeout: 5_000,
    },
  );
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

test("M-11 create chooser: rail Create opens the two-option chooser → vault capture options", async ({
  page,
}) => {
  await signIn(page);
  const rail = page.locator('nav[aria-label="Primary"]:visible');
  // The Create pillar is an action (chooser dialog), not a route (M-11).
  const create = rail.getByRole("button", { name: "Create" });
  await expect(create).toHaveAttribute("aria-haspopup", "dialog");
  await create.click();

  const chooser = page.getByRole("dialog", { name: "Create" });
  await expect(chooser).toBeVisible();
  await expect(page.getByTestId("create-choice-measure")).toContainText(
    "Two photos — about a minute",
  );
  // Non-designer arm: the post card routes to become-a-designer (B5 upsell).
  await expect(page.getByTestId("create-choice-post")).toContainText(
    "Become a designer to post",
  );

  // "Take measurements" hands off to B4 with the capture options open.
  await page.getByTestId("create-choice-measure").click();
  await page.waitForURL("**/dashboard/vault?capture=1");
  await expect(
    page.getByRole("dialog", { name: "Update measurements" }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: /Upload photos/ }),
  ).toBeVisible();
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
  await page.getByTestId("media-input").setInputFiles({
    name: "look.jpg",
    mimeType: "image/jpeg",
    buffer: TINY_JPEG,
  });
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

test("B6 own profile: the avatar renders plain — no freshness ring (MI-11, Decided 2026-07-20)", async ({
  page,
}) => {
  await signIn(page);
  // /dashboard/profile redirects to the canonical own-profile route.
  await page.goto("/dashboard/profile");
  await page.waitForURL("**/dashboard/kiki.adeyemi");
  const avatar = page.locator("header [data-ring]").first();
  // The freshness ring is a vault-header affordance (design.md §2 MI-11;
  // Figma B6-own 386:8321 ring=none) — a ringed profile avatar here would
  // be the audited regression.
  await expect(avatar).toHaveAttribute("data-ring", "none");
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

test("B7a: staff moderation queue — audit exemplar from boot; dismiss drops a row", async ({
  page,
}) => {
  await signIn(page);
  await page.goto("/dashboard/admin/moderation");
  const queue = page.getByTestId("moderation-queue");
  // Seeded canvas narrative: two open rows (spam comment + reported post
  // with author) and one actioned audit-trail exemplar.
  await expect(queue).toContainText("Buy followers cheap");
  await expect(queue).toContainText("Reported post by @amara.designs");
  await expect(page.getByTestId("audit-line")).toContainText(
    "hide_comment by @mod.sarah",
  );
  const spamRow = queue
    .locator("li")
    .filter({ hasText: "Buy followers cheap" });
  await spamRow.getByRole("button", { name: "Dismiss" }).click();
  await expect(queue).not.toContainText("Buy followers cheap");
  // The rest of the queue survives the dismissal.
  await expect(queue).toContainText("Reported post by @amara.designs");
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
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Open dispute" })
    .click();
  await expect(
    page.getByText("Disputed", { exact: true }).first(),
  ).toBeVisible();
  await expect(page.getByText(/frozen/i).first()).toBeVisible();

  // Confirm delivery from shipped → payout released.
  await page.goto("/dashboard/orders/req-apr-1044");
  await page.getByTestId("confirm-delivery").click();
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Confirm delivery" })
    .click();
  await expect(
    page.getByText("Delivered", { exact: true }).first(),
  ).toBeVisible();
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
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Decline" })
    .click();
  await expect(
    page.getByText("Declined", { exact: true }).first(),
  ).toBeVisible();

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
  const close = await request.post(
    "/api/mock/v1/requests/req-apr-1044/confirm-delivery",
    {
      headers: { "x-mock-actor": "kiki.adeyemi" },
    },
  );
  expect([200, 409]).toContain(close.status());
  const res = await request.post(
    "/api/mock/v1/posts/post-print-brothers/requests",
    {
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
    },
  );
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
  await picker.getByRole("button", { name: "15", exact: true }).first().click();
  await sheet.getByRole("button", { name: "Send quote" }).click();

  await expect(page.getByText("Quoted", { exact: true }).first()).toBeVisible();
  await expect(page.getByText(/₦58,000/).first()).toBeVisible();
});

// The 390 overflow sweep moved to e2e/mobile-responsive.spec.ts (P1
// mobile pass): every route, 390 + 768, plus wide-element containment.

// ---------------------------------------------------------------------------
// Cross-check pass (2026-07-20) — C1 date-picker geometry + C2 in-sheet
// select clipping, on a shared fixture order. Lives in this serial file
// because it mutates the store (kiki's request on post-evening-gown — its
// only seeded order is closed/cancelled and no journey above touches it),
// then drives maisonbisi's quote/decline sheets through the actor seam.
// ---------------------------------------------------------------------------

test.describe("order-sheet floating layers (shared fixture)", () => {
  let orderId: string;

  test.beforeAll(async ({ request }) => {
    const res = await request.post(
      "/api/mock/v1/posts/post-evening-gown/requests",
      {
        headers: {
          "x-mock-actor": "kiki.adeyemi",
          "idempotency-key": "e2e-order-sheet-geometry-fixture",
        },
        data: {
          session_id: "sess-recent-scan",
          notes: "Calendar/select geometry fixture",
          delivery: {
            recipient_name: "Kiki Adeyemi",
            phone: "+2348012345678",
            line1: "14 Adeola Odeku St",
            city: "Lagos",
            state: "Lagos",
            country: "NG",
          },
        },
      },
    );
    expect(res.status()).toBe(201);
    orderId = (await res.json()).id;
  });

  async function openOrderAsDesigner(page: Page) {
    await page.addInitScript(() => {
      window.sessionStorage.setItem("apparule.testmode.actor", "maisonbisi");
    });
    await signIn(page);
    await page.goto(`/dashboard/orders/${orderId}`);
  }

  async function openDueDatePicker(page: Page) {
    await openOrderAsDesigner(page);
    await page.getByRole("button", { name: "Send quote" }).click();
    await page.getByLabel("Due date").click();
    const picker = page.getByTestId("date-picker");
    await expect(picker).toBeVisible();
    // The panel is the popover content wrapping the grid.
    return { panel: picker.locator("xpath=.."), picker };
  }

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
    // No clipping: the point just inside the menu's bottom edge hit-tests
    // to the menu itself, not an overlaying sheet or scrollbox.
    const hit = await page.evaluate(() => {
      const lb = document.querySelector('[role="listbox"]')!;
      const r = lb.getBoundingClientRect();
      const el = document.elementFromPoint(r.x + r.width / 2, r.bottom - 5);
      return lb.contains(el);
    });
    expect(hit, "menu bottom edge is hit-testable").toBe(true);
  }

  test("date-picker panel matches the 87:1035 master anatomy", async ({
    page,
  }) => {
    const { panel, picker } = await openDueDatePicker(page);

    const anatomy = await panel.evaluate((el) => {
      const grid = el.querySelector(".grid-cols-7")!;
      const dayButtons = [...grid.querySelectorAll("button")];
      const sample = dayButtons[Math.floor(dayButtons.length / 2)];
      const scs = getComputedStyle(sample);
      const weekLabels = [...grid.children]
        .slice(0, 7)
        .map((c) => c.textContent);
      const weekCs = getComputedStyle(grid.children[0]);
      return {
        padding: getComputedStyle(el).padding,
        rowGap: getComputedStyle(grid).rowGap,
        weekLabels,
        weekWeight: weekCs.fontWeight,
        day: {
          w: (sample as HTMLElement).offsetWidth,
          h: (sample as HTMLElement).offsetHeight,
          fontSize: scs.fontSize,
        },
        dayCount: dayButtons.length,
      };
    });
    // Master: 16px panel padding — the grid never sits flush to the edges.
    expect(anatomy.padding).toBe("16px");
    // Master: rows separated by 8px.
    expect(anatomy.rowGap).toBe("8px");
    // Master: Sunday-first S M T W T F S, 12 semibold.
    expect(anatomy.weekLabels).toEqual(["S", "M", "T", "W", "T", "F", "S"]);
    expect(Number(anatomy.weekWeight)).toBeGreaterThanOrEqual(600);
    // Master: 36×32 pill day cells, 13px numerals.
    expect(anatomy.day.w).toBe(36);
    expect(anatomy.day.h).toBe(32);
    expect(anatomy.day.fontSize).toBe("13px");
    // Master: outside-month cells are blank — exactly the displayed
    // month's days render as buttons.
    const title = await panel
      .getByText(/^[A-Z][a-z]+ \d{4}$/)
      .first()
      .textContent();
    const shown = new Date(`1 ${title}`);
    const daysInMonth = new Date(
      shown.getFullYear(),
      shown.getMonth() + 1,
      0,
    ).getDate();
    expect(anatomy.dayCount).toBe(daysInMonth);

    // Today ring (master: 1px border-token ring) — only when today's month
    // is on screen.
    const now = new Date();
    if (
      now.getFullYear() === shown.getFullYear() &&
      now.getMonth() === shown.getMonth()
    ) {
      const todayBtn = picker.getByRole("button", {
        name: String(now.getDate()),
        exact: true,
      });
      const borderWidth = await todayBtn.evaluate(
        (el) => getComputedStyle(el).borderWidth,
      );
      expect(borderWidth).toBe("1px");
    }
  });

  for (const height of [900, 700]) {
    test(`date-picker stays inside the 1440×${height} viewport (flip/clamp, no page scrollbar growth)`, async ({
      page,
    }) => {
      await page.setViewportSize({ width: 1440, height });
      const scrollHeight = () =>
        page.evaluate(() => document.documentElement.scrollHeight);
      const { panel } = await openDueDatePicker(page);
      const before = await scrollHeight();

      const box = await panel.boundingBox();
      expect(box, "open calendar has a bounding box").not.toBeNull();
      expect(box!.y, "top edge inside viewport").toBeGreaterThanOrEqual(0);
      expect(
        box!.y + box!.height,
        "bottom edge inside viewport",
      ).toBeLessThanOrEqual(height);

      const trigger = await page.getByLabel("Due date").boundingBox();
      if (trigger!.y + trigger!.height + box!.height + 8 > height) {
        // Not enough room below the trigger: the panel must flip above it.
        expect(
          box!.y + box!.height,
          "panel flips above the trigger",
        ).toBeLessThanOrEqual(trigger!.y);
      }
      // The open popover never gives the document extra scroll height.
      expect(await scrollHeight()).toBe(before);
    });
  }

  for (const height of [900, 700]) {
    test(`decline-reason select inside the order sheet is unclipped at 1440×${height}`, async ({
      page,
    }) => {
      await page.setViewportSize({ width: 1440, height });
      await openOrderAsDesigner(page);
      await page.getByRole("button", { name: "Decline" }).click();
      await page.getByLabel("Decline reason").click();
      await expectMenuUnclipped(page, height);
    });
  }
});
