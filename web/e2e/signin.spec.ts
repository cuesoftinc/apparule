// TEST_MODE smoke: the X-1 journey — /signin single CTA → dashboard.
import { expect, test } from "@playwright/test";

test.describe("TEST_MODE auth smoke", () => {
  test("signin → dashboard redirect", async ({ page }) => {
    await page.goto("/signin");

    // Exactly one auth CTA (X-1, flows/auth.md).
    const cta = page.getByRole("button", { name: /continue with google/i });
    await expect(cta).toBeVisible();
    expect(await page.getByRole("button").count()).toBe(1);

    await cta.click();
    await page.waitForURL("**/dashboard");

    // Signed in as the seeded TEST_MODE account.
    await expect(page.getByTestId("signed-in-as")).toContainText(
      "kiki.adeyemi",
    );
  });

  test("mock server serves the seeded feed", async ({ request }) => {
    const res = await request.get("/api/mock/v1/feed");
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.items.length).toBeGreaterThan(0);
    expect(body.items[0].designer.username).toBeTruthy();
  });
});
