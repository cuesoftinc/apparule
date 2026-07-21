// NavRail state sweep [Directive 2026-07-19]: the dashboard chrome is a
// viewport-driven rail — collapsed 72px below 1264, expanded 244px at
// ≥1264 — with NO user toggle and NO persisted expanded state. Two duties:
//
// 1. Mobile (<md): an expanded rail must NEVER squeeze the main content.
//    Apparule's shape makes that structurally impossible (the expanded
//    rail is display-hidden below 1264 and nothing can re-enable it);
//    this spec pins the shape so a future toggle/persistence change that
//    leaks an expanded rail into mobile fails CI.
// 2. Desktop ≥1264: the expanded rail squeezes the content column hardest
//    at 1264 — every dashboard route must reflow cleanly in BOTH states
//    (no document side-scroll, no element escaping the viewport outside a
//    fitting scroll container).
import { expect, test, type Page } from "@playwright/test";

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

// The widest screens — screenshotted in both rail states for the report.
const WORST_OFFENDERS = [
  "/dashboard/orders/req-apr-1042",
  "/dashboard/explore",
  "/dashboard/admin/moderation",
  "/dashboard/earnings",
];

async function signIn(page: Page) {
  await page.goto("/signin");
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
}

async function settle(page: Page, route: string) {
  await page.goto(route);
  await expect(page.locator("main")).toBeVisible();
  await page.waitForTimeout(400);
}

// Prefix match: the two rails carry distinct landmark labels
// ("Primary" expanded / "Primary, compact" collapsed — landmark rules).
const visibleRail = (page: Page) =>
  page.locator('nav[aria-label^="Primary"]:visible');

const docOverflow = (page: Page) =>
  page.evaluate(
    () =>
      document.documentElement.scrollWidth -
      document.documentElement.clientWidth,
  );

// Every rendered element inside <main> must either fit the viewport
// horizontally or sit inside an overflow-x scroll container that itself
// fits (the mobile-sweep containment rule, applied to the squeezed
// desktop content column).
const contentColumnViolations = (page: Page) =>
  page.evaluate(() => {
    const vw = document.documentElement.clientWidth;
    const violations: string[] = [];
    const fits = (r: DOMRect) => r.right <= vw + 1 && r.left >= -1;
    const scrollContainerOf = (el: Element): Element | null => {
      for (let a = el.parentElement; a; a = a.parentElement) {
        const s = getComputedStyle(a);
        if (s.overflowX === "auto" || s.overflowX === "scroll") return a;
      }
      return null;
    };
    const main = document.querySelector("main");
    if (!main) return ["no <main> landmark"];
    for (const el of main.querySelectorAll("*")) {
      const r = el.getBoundingClientRect();
      if (!r.width || !r.height) continue;
      if (fits(r)) continue;
      const container = scrollContainerOf(el);
      if (!container) {
        violations.push(
          `<${el.tagName.toLowerCase()} class="${el.className
            .toString()
            .slice(0, 60)}"> escapes the viewport without a scroll container`,
        );
      } else if (!fits(container.getBoundingClientRect())) {
        violations.push(
          `<${el.tagName.toLowerCase()}> scroll container itself escapes the viewport`,
        );
      }
      if (violations.length >= 5) break;
    }
    return violations;
  });

test("mobile 390: only the collapsed 72px rail exists — an expanded rail cannot squeeze content", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await signIn(page);
  for (const route of ["/dashboard", "/dashboard/orders", "/dashboard/vault"]) {
    await settle(page, route);
    const rail = visibleRail(page);
    await expect(rail, `${route}: one visible rail`).toHaveCount(1);
    await expect(rail).toHaveAttribute("data-expanded", "false");
    const railBox = (await rail.boundingBox())!;
    expect(railBox.width, `${route}: collapsed rail width`).toBeLessThanOrEqual(
      72,
    );
    // the expanded (244px) rail is display-hidden, not merely offscreen
    await expect(
      page.locator('nav[aria-label^="Primary"][data-expanded="true"]'),
    ).toBeHidden();
    // main takes the rest of the viewport — content is never squeezed
    const mainBox = (await page.locator("main").boundingBox())!;
    expect(
      mainBox.width,
      `${route}: content column width`,
    ).toBeGreaterThanOrEqual(390 - 72 - 2);
    expect(
      await docOverflow(page),
      `${route}: no side-scroll`,
    ).toBeLessThanOrEqual(2);
  }
});

for (const width of [1264, 1440]) {
  test(`expanded rail at ${width}: every dashboard route reflows inside the squeezed content column`, async ({
    page,
  }) => {
    await page.setViewportSize({ width, height: 900 });
    await signIn(page);
    for (const route of DASHBOARD_ROUTES) {
      await settle(page, route);
      const rail = visibleRail(page);
      await expect(rail, `${route}: one visible rail`).toHaveCount(1);
      await expect(rail).toHaveAttribute("data-expanded", "true");
      expect(
        (await rail.boundingBox())!.width,
        `${route}: expanded rail width`,
      ).toBeGreaterThanOrEqual(243);
      expect(
        await docOverflow(page),
        `${route}: no horizontal document scroll at ${width}`,
      ).toBeLessThanOrEqual(2);
      expect(
        await contentColumnViolations(page),
        `${route}: content containment at ${width}`,
      ).toEqual([]);
    }
  });
}

test("worst offenders screenshot in both rail states (1263 collapsed / 1264 expanded)", async ({
  page,
}, testInfo) => {
  await signIn(page);
  for (const route of WORST_OFFENDERS) {
    for (const width of [1263, 1264]) {
      await page.setViewportSize({ width, height: 900 });
      await settle(page, route);
      const state = width >= 1264 ? "expanded" : "collapsed";
      await expect(visibleRail(page)).toHaveAttribute(
        "data-expanded",
        String(width >= 1264),
      );
      await testInfo.attach(`${route.replaceAll("/", "_")}@${width}-${state}`, {
        body: await page.screenshot({ fullPage: true }),
        contentType: "image/png",
      });
    }
  }
});
