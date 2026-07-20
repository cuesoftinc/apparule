import { test, expect } from "@playwright/test";

/**
 * Public API reference (F0-8, APP-004) — /docs/api embeds the Scalar
 * interactive reference rendered from the repo's canonical OpenAPI
 * document, served at /docs/api/openapi.yaml. Public surface: no auth,
 * marketing nav chrome, reachable from the footer's Docs column.
 */
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

    // Scalar hydrates client-side from /docs/api/openapi.yaml: the spec
    // title and a known operation summary (GET /api/v1/me) must render.
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });
    await expect(
      page.getByText("Resolve caller's account").first(),
    ).toBeVisible();
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
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });

    // Scalar mirrors the resolved theme on body (light-mode/dark-mode).
    const body = page.locator("body");
    await expect(body).toHaveClass(/light-mode/);

    // system mode (default) follows an OS scheme flip live.
    await page.emulateMedia({ colorScheme: "dark" });
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await expect(body).toHaveClass(/dark-mode/, { timeout: 15_000 });

    // Explicit choice via the nav toggle wins over the OS (dark stays after
    // cycling system → light → the embed resyncs to light).
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
    await expect(
      page.getByRole("heading", { name: "Apparule API" }),
    ).toBeVisible({ timeout: 20_000 });
  });
});
