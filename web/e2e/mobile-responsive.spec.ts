// Mobile-responsiveness sweep [Directive P1 2026-07-19]: home AND every
// dashboard route render fully inside the mobile boundary at 390 (768
// sanity) — the document itself never side-scrolls, and known-wide elements
// (tables, code snippets, rails) sit in horizontal-scroll containers that
// scroll WITHIN the viewport. Runs in TEST_MODE against the mock server.
import { expect, test, type Page } from "@playwright/test";

// Every route the web app serves (web-implementation.md §4 route map).
const PUBLIC_ROUTES = [
  "/",
  "/signin",
  "/p/post-ankara-gown",
  "/definitely-not-a-route", // branded not-found
];

const DASHBOARD_ROUTES = [
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

async function signIn(page: Page) {
  await page.goto("/signin");
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
}

async function settle(page: Page, route: string) {
  await page.goto(route);
  // networkidle never settles against the dev server (HMR socket) — wait
  // for the screen's <main> content instead.
  await expect(page.locator("main")).toBeVisible();
  await page.waitForTimeout(400);
}

const docOverflow = (page: Page) =>
  page.evaluate(
    () =>
      document.documentElement.scrollWidth -
      document.documentElement.clientWidth,
  );

// Known-wide elements must be reachable by scrolling WITHIN a container:
// each sits inside an ancestor with overflow-x auto/scroll whose own box
// fits the viewport. Returns human-readable violations.
const wideElementViolations = (page: Page) =>
  page.evaluate(() => {
    const vw = document.documentElement.clientWidth;
    const violations: string[] = [];
    const fitsViewport = (r: DOMRect) => r.right <= vw + 1 && r.left >= -1;
    const scrollContainerOf = (el: Element): Element | null => {
      for (let a = el.parentElement; a; a = a.parentElement) {
        const s = getComputedStyle(a);
        if (s.overflowX === "auto" || s.overflowX === "scroll") return a;
      }
      return null;
    };
    for (const el of document.querySelectorAll("table, pre, code")) {
      const r = el.getBoundingClientRect();
      if (!r.width || !r.height) continue;
      if (fitsViewport(r)) continue; // narrow enough — nothing to prove
      const container = scrollContainerOf(el);
      if (!container) {
        violations.push(
          `<${el.tagName.toLowerCase()}> wider than viewport without a scroll container`,
        );
      } else if (!fitsViewport(container.getBoundingClientRect())) {
        violations.push(
          `<${el.tagName.toLowerCase()}> scroll container itself escapes the viewport`,
        );
      }
    }
    return violations;
  });

for (const width of [390, 768]) {
  test(`no horizontal document overflow at ${width} — public + dashboard routes`, async ({
    page,
  }) => {
    await page.setViewportSize({ width, height: width === 390 ? 844 : 1024 });
    for (const route of PUBLIC_ROUTES) {
      await settle(page, route);
      expect(
        await docOverflow(page),
        `${route} horizontal overflow at ${width}`,
      ).toBeLessThanOrEqual(2);
    }
    await signIn(page);
    for (const route of DASHBOARD_ROUTES) {
      await settle(page, route);
      expect(
        await docOverflow(page),
        `${route} horizontal overflow at ${width}`,
      ).toBeLessThanOrEqual(2);
    }
  });
}

test("wide elements (tables, code) sit in horizontal-scroll containers at 390", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await signIn(page);
  for (const route of [...PUBLIC_ROUTES, ...DASHBOARD_ROUTES]) {
    await settle(page, route);
    expect(
      await wideElementViolations(page),
      `${route} wide-element containment at 390`,
    ).toEqual([]);
  }
});

test("comparison table scrolls within its card at 390 — CTAs reachable", async ({
  page,
}) => {
  // Regression: the A9 Cloud-vs-OSS table clipped its "Self-host it" CTA
  // behind overflow-hidden at 390 (P1 mobile pass).
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  const table = page.locator("table").first();
  await table.scrollIntoViewIfNeeded();
  const selfHost = page.getByRole("button", { name: "Self-host it" });
  await expect(selfHost).toBeVisible();
  // scroll the container to the end — the CTA must land inside the viewport
  const reachable = await selfHost.evaluate((el) => {
    let scroller: HTMLElement | null = el.parentElement;
    while (scroller && getComputedStyle(scroller).overflowX !== "auto") {
      scroller = scroller.parentElement;
    }
    if (!scroller) return getComputedStyle(el).visibility === "visible";
    scroller.scrollLeft = scroller.scrollWidth;
    const r = el.getBoundingClientRect();
    return r.right <= document.documentElement.clientWidth + 1;
  });
  expect(reachable, "Self-host CTA reachable by in-card scroll").toBe(true);
});

test("request stepper snapshot picker fits the 390 viewport", async ({
  page,
}) => {
  // Regression: fieldset's default min-inline-size:min-content defeated
  // SessionRow truncation and pushed step 1 content past the viewport.
  await page.setViewportSize({ width: 390, height: 844 });
  await signIn(page);
  await page.goto("/dashboard");
  const cta = page
    .getByRole("button", { name: /request this outfit/i })
    .first();
  await cta.scrollIntoViewIfNeeded();
  await cta.click();
  const step1 = page.getByTestId("stepper-step-1");
  await expect(step1).toBeVisible();
  const pokes = await page.evaluate(() => {
    const dlg = document.querySelector('[role="dialog"]');
    if (!dlg) return -1;
    const vw = document.documentElement.clientWidth;
    let count = 0;
    for (const el of dlg.querySelectorAll("*")) {
      const r = el.getBoundingClientRect();
      if (r.width && (r.right > vw + 1 || r.left < -1)) count++;
    }
    return count;
  });
  expect(pokes, "no stepper content outside the 390 viewport").toBe(0);
});

test("order-thread image attachments stay inside the bubble at 390", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await signIn(page);
  await settle(page, "/dashboard/orders/req-apr-1042");
  const images = page.locator("[data-content='image']");
  const count = await images.count();
  expect(count).toBeGreaterThan(0);
  for (let i = 0; i < count; i++) {
    const box = await images.nth(i).boundingBox();
    expect(box, `attachment ${i} rendered`).not.toBeNull();
    expect(box!.x, `attachment ${i} left edge`).toBeGreaterThanOrEqual(-1);
    expect(
      box!.x + box!.width,
      `attachment ${i} right edge`,
    ).toBeLessThanOrEqual(391);
  }
});
