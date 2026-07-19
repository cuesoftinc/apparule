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
    await expect(
      page.locator('nav[aria-label="Primary"]:visible'),
    ).toHaveCount(1);
  });

  test("mock server serves the seeded feed", async ({ request }) => {
    const res = await request.get("/api/mock/v1/feed");
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.items.length).toBeGreaterThan(0);
    expect(body.items[0].designer.username).toBeTruthy();
  });
});
