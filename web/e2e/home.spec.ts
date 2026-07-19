// "Marketing site" journey (design.md §8.4, web-implementation.md §7):
// Part A scroll — every section renders — plus the FAQ accordion, the
// Try Cloud / Sign in CTA handoff into /signin, and the theme toggle.
// Runs in TEST_MODE: the star badge deterministically keeps its neutral
// "Star" label (no third-party fetch in CI).
import { expect, test } from "@playwright/test";

test.describe("Marketing site — home page", () => {
  test("all Part A sections render top to bottom", async ({ page }) => {
    await page.goto("/");

    // A2 hero
    await expect(
      page.getByRole("heading", { name: "Two photos. A perfect fit." }),
    ).toBeVisible();
    await expect(page.getByTestId("hero-phone")).toBeVisible();

    // A1 nav — neutral star badge in TEST_MODE (accuracy standard)
    await expect(page.getByTestId("star-badge")).toContainText("Star");

    // A3 stat band — the honest product claims
    await expect(page.getByText("±2 cm", { exact: true })).toBeVisible();
    await expect(page.getByText("2 photos", { exact: true })).toBeVisible();
    await expect(page.getByText("30 days")).toBeVisible();

    // A4 walkthrough
    await expect(
      page.getByRole("heading", { name: "How it works" }),
    ).toBeVisible();
    await expect(page.getByTestId("walkthrough-rail")).toBeVisible();

    // A4b deep-dives
    await expect(
      page.getByRole("heading", { name: "Built around your measurements" }),
    ).toBeVisible();
    expect(await page.getByTestId("deep-dive-panel").count()).toBe(4);

    // A5 SMPL
    await expect(
      page.getByRole("heading", { name: "AI-assisted body modeling" }),
    ).toBeVisible();

    // A6 designers
    await expect(
      page.getByRole("heading", {
        name: "Post outfits, get commissioned, get paid",
      }),
    ).toBeVisible();

    // A7b developers
    await expect(
      page.getByRole("heading", {
        name: "For developers — hack on the interesting parts",
      }),
    ).toBeVisible();
    expect(await page.getByTestId("dev-topic-card").count()).toBe(3);

    // A7c self-host + A7 architecture diagram
    await expect(
      page.getByRole("heading", { name: "Self-host — own your data" }),
    ).toBeVisible();
    await expect(page.getByText("docker compose up -d")).toBeVisible();
    await expect(page.getByTestId("architecture-diagram")).toBeVisible();

    // A9 comparison
    await expect(
      page.getByRole("heading", { name: "Cloud or self-host — same product" }),
    ).toBeVisible();
    await expect(
      page.getByRole("button", { name: "Start on Cloud" }),
    ).toBeVisible();

    // A9b FAQ
    await expect(
      page.getByRole("heading", { name: "Frequently asked" }),
    ).toBeVisible();

    // A8 community
    await expect(page.getByText("Join the apparule Discord")).toBeVisible();

    // A9c final CTA band
    await expect(
      page.getByRole("heading", {
        name: "Get measured once. Dress like it was always made for you.",
      }),
    ).toBeVisible();
    await expect(
      page.getByText("Open source · MIT licensed · Self-host in one line"),
    ).toBeVisible();

    // A10 footer
    await expect(page.getByRole("contentinfo")).toBeVisible();
    await expect(
      page
        .getByRole("contentinfo")
        .getByRole("link", { name: "Privacy", exact: true }),
    ).toBeVisible();
  });

  test("FAQ accordion: first row open, one open at a time, deep-linkable", async ({
    page,
  }) => {
    await page.goto("/");
    const first = page.getByRole("button", {
      name: "How accurate are camera measurements?",
    });
    const second = page.getByRole("button", {
      name: "What happens to my photos?",
    });

    await expect(first).toHaveAttribute("aria-expanded", "true");
    await expect(second).toHaveAttribute("aria-expanded", "false");

    await second.click();
    await expect(second).toHaveAttribute("aria-expanded", "true");
    await expect(first).toHaveAttribute("aria-expanded", "false");
    await expect(
      page.getByText(/auto-deleted within 30 days/),
    ).toBeVisible();

    // deep link opens the linked row
    await page.goto("/#faq-5");
    await expect(
      page.getByRole("button", { name: "What license is Apparule under?" }),
    ).toHaveAttribute("aria-expanded", "true");
  });

  test("Try Cloud CTA hands off to /signin", async ({ page }) => {
    await page.goto("/");
    await page
      .locator("nav")
      .getByRole("button", { name: "Try Cloud" })
      .click();
    await page.waitForURL("**/signin");
    await expect(
      page.getByRole("button", { name: /continue with google/i }),
    ).toBeVisible();
  });

  test("Sign in link lands on /signin", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: "Sign in" }).click();
    await page.waitForURL("**/signin");
  });

  test("hero Self Host CTA scrolls to the self-host section", async ({
    page,
  }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Self Host" }).first().click();
    await expect(
      page.getByRole("heading", { name: "Self-host — own your data" }),
    ).toBeInViewport();
  });

  test("theme toggle switches light and dark", async ({ page }) => {
    await page.goto("/");
    const html = page.locator("html");

    await page.getByRole("button", { name: /switch to dark theme/i }).click();
    await expect(html).toHaveAttribute("data-theme", "dark");

    await page.getByRole("button", { name: /switch to light theme/i }).click();
    await expect(html).toHaveAttribute("data-theme", "light");
  });

  test("snippet copy button morphs to the copied check", async ({ page }) => {
    await page.goto("/");
    await page
      .getByRole("heading", { name: "Self-host — own your data" })
      .scrollIntoViewIfNeeded();
    await page.getByRole("button", { name: "Copy command" }).click();
    await expect(page.getByTestId("copied-check")).toBeVisible();
  });
});
