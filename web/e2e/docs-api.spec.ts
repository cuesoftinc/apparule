import { test, expect, type Page } from "@playwright/test";

/**
 * Public API reference (F0-8, APP-004) — /docs/api embeds the Scalar
 * interactive reference rendered from the repo's canonical OpenAPI
 * document, served at /docs/api/openapi.yaml. Public surface: no auth,
 * marketing nav chrome, reachable from the footer's Docs column.
 */

/**
 * Payload diet (2026-07-21): Scalar mounts on first user intent (pointer /
 * key / wheel / touch / scroll, or the explicit load button) — a mouse
 * nudge is the smallest trusted gesture. Every navigation needs re-arming,
 * and a gesture racing hydration is inert, so nudge until the placeholder's
 * Load affordance gives way to the mounting reference.
 */
async function armReference(page: Page) {
  await expect(async () => {
    await page.mouse.move(12, 12);
    await page.mouse.move(24, 24);
    await expect(
      page.getByRole("button", { name: "Load the interactive API reference" }),
    ).toHaveCount(0, { timeout: 1_000 });
  }).toPass({ timeout: 15_000 });
}
test.describe("API reference — /docs/api", () => {
  test("route 200s and Scalar renders operations from the spec", async ({
    page,
  }) => {
    const response = await page.goto("/docs/api");
    expect(response?.status()).toBe(200);

    // Marketing nav chrome is present on the public docs surface.
    await expect(
      page.getByRole("link", { name: "Star cuesoftinc/apparule on GitHub" }),
    ).toBeVisible();

    // Arm the payload gate (2026-07-21): Scalar mounts on the first user
    // gesture — a pointer move is the lightest real-visitor signal.
    // Scalar then hydrates client-side from /docs/api/openapi.yaml: the
    // spec title and a known operation summary (GET /api/v1/me) render.
    await armReference(page);
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });
    await expect(
      page.getByText("Resolve caller's account").first(),
    ).toBeVisible();

    // Scalar's developer toolbar is author chrome — never on the public
    // reference (showDeveloperTools: "never"; the default leaks it on
    // localhost-class hosts, which is exactly how e2e runs).
    await expect(page.getByText("Developer Tools")).toHaveCount(0);
  });

  test("payload gate: a bounce never mounts Scalar; the first gesture does", async ({
    page,
  }) => {
    await page.goto("/docs/api");
    // Pre-gesture: the SSR'd placeholder reserves the embed's viewport
    // slice and offers the explicit Load affordance — the ~1MB Scalar
    // chunk group is not on the bounce path.
    await expect(
      page.getByRole("button", { name: "Load the interactive API reference" }),
    ).toBeVisible();
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toHaveCount(0);

    // First gesture arms the gate; the reference streams in.
    await armReference(page);
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });
  });

  test("payload gate: the explicit Load button serves the gesture-free path", async ({
    page,
  }) => {
    await page.goto("/docs/api");
    const load = page.getByRole("button", {
      name: "Load the interactive API reference",
    });
    await expect(load).toBeVisible();
    // SR virtual-cursor activation produces a click with no pointer or
    // key gesture — dispatch a bare click to walk that exact path (with
    // a toPass retry: a dispatch racing hydration is inert).
    await expect(async () => {
      await load.dispatchEvent("click");
      await expect(
        page.getByRole("heading", { name: "Apparule API" }),
      ).toBeVisible({ timeout: 2_000 });
    }).toPass({ timeout: 20_000 });
  });

  test("the OpenAPI document is served at /docs/api/openapi.yaml", async ({
    request,
  }) => {
    const response = await request.get("/docs/api/openapi.yaml");
    expect(response.status()).toBe(200);
    const body = await response.text();
    expect(body).toContain("openapi: 3.1.0");
    expect(body).toContain("title: Apparule API");
  });

  test("header behaves: nav stays visible over the embed, one scroll container", async ({
    page,
  }) => {
    await page.goto("/docs/api");
    await armReference(page);
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });

    // One coherent scroll container: the page scrolls; no full-viewport
    // inner scroller wraps the embed (Scalar's viewport math is offset by
    // --scalar-custom-header-height so its sidebar fits under the nav).
    const layout = await page.evaluate(() => ({
      pageScrollable:
        document.documentElement.scrollHeight > window.innerHeight,
      fullHeightInnerScrollers: [...document.querySelectorAll("*")].filter(
        (el) =>
          el.scrollHeight > el.clientHeight + 10 &&
          ["auto", "scroll"].includes(getComputedStyle(el).overflowY) &&
          el.clientHeight >= window.innerHeight,
      ).length,
    }));
    expect(layout.pageScrollable).toBe(true);
    expect(layout.fullHeightInnerScrollers).toBe(0);

    // After scrolling, the marketing nav (sticky) is still fully visible —
    // Scalar's sticky sidebar must not paint over it (isolate + offset).
    await page.mouse.wheel(0, 800);
    await expect(
      page.getByRole("link", { name: "Star cuesoftinc/apparule on GitHub" }),
    ).toBeVisible();
    const navBox = await page
      .locator("nav")
      .first()
      .evaluate((el) => el.getBoundingClientRect().top);
    expect(navBox).toBe(0);
  });

  test("the embed follows the tri-state theme, incl. a live OS flip in system mode", async ({
    page,
  }) => {
    await page.emulateMedia({ colorScheme: "light" });
    await page.goto("/docs/api");
    await armReference(page);
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });

    // Scalar mirrors the resolved theme on body (light-mode/dark-mode).
    // Fresh boot is light, the design default (key absent).
    const body = page.locator("body");
    await expect(body).toHaveClass(/light-mode/);

    // Select system explicitly (light → dark → system) to exercise live
    // OS-flip tracking.
    await page
      .getByRole("button", { name: "Theme: light — switch to dark" })
      .click();
    await page
      .getByRole("button", { name: "Theme: dark — switch to system" })
      .click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
    await expect(body).toHaveClass(/light-mode/, { timeout: 15_000 });

    // system mode follows an OS scheme flip live.
    await page.emulateMedia({ colorScheme: "dark" });
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await expect(body).toHaveClass(/dark-mode/, { timeout: 15_000 });

    // Explicit choice via the nav toggle wins over the OS (system stays
    // dark from the OS flip; cycling system → light and the embed resyncs
    // to light).
    await page
      .getByRole("button", { name: "Theme: system — switch to light" })
      .click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
    await expect(body).toHaveClass(/light-mode/, { timeout: 15_000 });
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });

    // The choice persists across reload (stored at apparule.theme).
    await page.reload();
    await armReference(page);
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
    await expect(body).toHaveClass(/light-mode/, { timeout: 20_000 });
  });

  test("the footer API reference link navigates to /docs/api", async ({
    page,
  }) => {
    await page.goto("/");
    await page
      .locator("footer")
      .getByRole("link", { name: "API reference", exact: true })
      .click();
    await page.waitForURL("**/docs/api");
    await armReference(page);
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });
  });
});
