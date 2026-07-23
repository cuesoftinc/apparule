// P15 skip-link lock (fleet a11y canon): the skip link is the FIRST
// focusable element on every route — one Tab from a fresh load lands on
// it — and activating it moves focus to the page's single
// <main id="main" tabIndex={-1}>. Runs in TEST_MODE against the mock
// server; covers the marketing home and the authed dashboard shell.
import { expect, test, type Page } from "@playwright/test";

async function expectSkipLinkWorks(page: Page) {
  await page.keyboard.press("Tab");
  const link = page.getByRole("link", { name: "Skip to content" });
  await expect(link, "first Tab lands on the skip link").toBeFocused();
  await expect(link, "focus reveals the visually-hidden link").toBeInViewport();
  await page.keyboard.press("Enter");
  await expect(
    page.locator("main#main"),
    "activation moves focus to main",
  ).toBeFocused();
}

test("home: first Tab is the skip link; Enter focuses <main>", async ({
  page,
}) => {
  await page.goto("/");
  await expect(page.getByTestId("hero-phone")).toBeVisible();
  await expectSkipLinkWorks(page);
});

test("dashboard: first Tab is the skip link; Enter focuses <main>", async ({
  page,
}) => {
  await page.goto("/signin");
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
  // Fresh document load: "first Tab" is a fresh-load guarantee (after a
  // client-side nav Chromium keeps its sequential-focus starting point at
  // the removed element's position). The reload also exercises session
  // restore via the P16 sessionStorage key (`apparule.test-session`).
  await page.goto("/dashboard");
  await expect(page.locator("main#main")).toBeVisible();
  await expectSkipLinkWorks(page);
});
