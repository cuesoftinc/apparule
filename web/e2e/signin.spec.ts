// TEST_MODE smoke: the X-1 journey — /signin single CTA → dashboard.
import { expect, test } from "@playwright/test";

test.describe("TEST_MODE auth smoke", () => {
  test("signin → dashboard redirect", async ({ page }) => {
    await page.goto("/signin");

    // Exactly one auth CTA (X-1, flows/auth.md) — scoped to the screen
    // content (the Next dev-tools overlay adds its own button in dev).
    const cta = page.getByRole("button", { name: /continue with google/i });
    await expect(cta).toBeVisible();
    expect(await page.locator("main").getByRole("button").count()).toBe(1);

    await cta.click();
    await page.waitForURL("**/dashboard");

    // Signed in as the seeded TEST_MODE account — W3 lands on the B1 feed
    // (the W0 stub's "signed-in-as" line retired with the stub).
    await expect(page.getByTestId("feed-list")).toBeVisible();
    await expect(page.locator('nav[aria-label="Primary"]:visible')).toHaveCount(
      1,
    );
  });

  test("legal links point at the canonical Cuesoft policies", async ({
    page,
  }) => {
    await page.goto("/signin");
    await expect(page.getByRole("link", { name: "Terms" })).toHaveAttribute(
      "href",
      "https://terms.cuesoft.io",
    );
    await expect(
      page.getByRole("link", { name: "Privacy Policy" }),
    ).toHaveAttribute("href", "https://privacy.cuesoft.io");
  });

  test("mock server serves the seeded feed", async ({ request }) => {
    const res = await request.get("/api/mock/v1/feed");
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.items.length).toBeGreaterThan(0);
    expect(body.items[0].designer.username).toBeTruthy();
  });

  // Cold-start matrix (flows/auth.md §2, ratified 2026-07-22) — the web
  // sibling of mobile's boot-gate tests: restore resolves before either
  // surface routes, and each surface guards its wrong-state visitor.
  test("cold start signed out: /dashboard replaces to /signin with no dashboard paint", async ({
    page,
  }) => {
    await page.goto("/dashboard");
    await page.waitForURL("**/signin");
    await expect(
      page.getByRole("button", { name: /continue with google/i }),
    ).toBeVisible();
    // The dashboard never painted content for the signed-out visitor.
    await expect(page.getByTestId("feed-list")).toHaveCount(0);
  });

  test("reverse guard: a signed-in visit to /signin is replaced to /dashboard", async ({
    page,
  }) => {
    await page.goto("/signin");
    await page.getByRole("button", { name: /continue with google/i }).click();
    await page.waitForURL("**/dashboard");

    // Same tab (TEST_MODE session is sessionStorage-held): /signin is not a
    // reachable surface while signed in — the gate replaces to the app.
    await page.goto("/signin");
    await page.waitForURL("**/dashboard");
    await expect(page.getByTestId("feed-list")).toBeVisible();
    await expect(
      page.getByRole("button", { name: /continue with google/i }),
    ).toHaveCount(0);
  });
});
