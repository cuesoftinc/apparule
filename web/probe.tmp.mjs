import { chromium } from "@playwright/test";
const browser = await chromium.launch();
const page = await browser.newPage();
await page.addInitScript(() => {
  window.sessionStorage.setItem("apparule.testmode.actor", "tunde.o");
});
await page.goto("http://localhost:3311/signin");
await page.getByRole("button", { name: /continue with google/i }).click();
await page.waitForURL("**/dashboard");
await page.goto("http://localhost:3311/dashboard/orders");
await page.getByRole("tab", { name: "As designer" }).click();
await page.waitForTimeout(1200);
console.log(await page.getByTestId("orders-list").ariaSnapshot().catch(e => "no list: " + e.message.split("\n")[0]));
await browser.close();
