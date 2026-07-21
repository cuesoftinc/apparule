// Overlay focus-restore canon (2026-07-21 a11y audit, fleet finding P4):
// closing any Sheet/modal must return focus to the element that opened it.
// The Sheets are controlled Radix dialogs without a RadixDialog.Trigger, so
// before the fix Escape dropped focus on <body> — invisible to keyboard and
// screen-reader users. Probe shape: open → move focus inside → Escape →
// dialog closed AND focus is back on the trigger.
import { expect, test, type Page } from "@playwright/test";

async function signIn(page: Page) {
  await page.goto("/signin");
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
  await page.waitForSelector('[data-testid="feed-list"]');
}

test("post-options sheet returns focus to its trigger on Escape", async ({
  page,
}) => {
  await signIn(page);
  const trigger = page
    .getByTestId("post-card")
    .first()
    .getByRole("button", { name: "More options" });
  await trigger.click();

  const dialog = page.getByRole("dialog", { name: "Post options" });
  await expect(dialog).toBeVisible();
  // The dialog is announced as modal (audit: ariaModal was null).
  await expect(dialog).toHaveAttribute("aria-modal", "true");

  // Move focus deeper into the sheet before dismissing — restore must not
  // depend on focus still sitting on the initially-focused element.
  await page.keyboard.press("Tab");
  await page.keyboard.press("Escape");

  await expect(dialog).toBeHidden();
  await expect(trigger).toBeFocused();
});

test("request stepper sheet returns focus to its trigger on Escape", async ({
  page,
}) => {
  await signIn(page);
  const trigger = page
    .getByTestId("post-card")
    .first()
    .getByRole("button", { name: "Request this outfit" });
  await trigger.click();

  const dialog = page.getByRole("dialog", { name: "Request this outfit" });
  await expect(dialog).toBeVisible();

  await page.keyboard.press("Tab");
  await page.keyboard.press("Escape");

  await expect(dialog).toBeHidden();
  await expect(trigger).toBeFocused();
});
