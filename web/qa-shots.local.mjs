import { chromium } from "@playwright/test";
const OUT = "/private/tmp/claude-501/-Users-inertia-apparule/64ae81ff-27f5-42d2-81c5-abc4cebd48e2/scratchpad/apparule-w3/shots";
const BASE = "http://localhost:3311";
const routes = [
  ["b1-feed", "/dashboard"],
  ["b2-explore", "/dashboard/explore"],
  ["b3-orders", "/dashboard/orders"],
  ["b3-order-detail", "/dashboard/orders/req-apr-1042"],
  ["b4-vault", "/dashboard/vault"],
  ["b5-create", "/dashboard/create"],
  ["b6-profile-designer", "/dashboard/amara.designs"],
  ["b6-profile-self", "/dashboard/kiki.adeyemi"],
  ["b7-settings", "/dashboard/settings"],
  ["b7-settings-notifications", "/dashboard/settings/notifications"],
  ["b7-settings-privacy", "/dashboard/settings/privacy"],
  ["b7-settings-account", "/dashboard/settings/account"],
  ["b7a-moderation", "/dashboard/admin/moderation"],
  ["b8-onboarding", "/dashboard/designer/onboarding"],
  ["b9-earnings", "/dashboard/earnings"],
];
const browser = await chromium.launch();
for (const theme of ["dark"]) {
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await ctx.newPage();
  await page.addInitScript((t) => window.localStorage.setItem("apparule.theme", t), theme);
  await page.request.post(`${BASE}/api/mock/v1/testing/reset`);
  await page.goto(`${BASE}/signin`);
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
  for (const [name, route] of routes) {
    await page.goto(`${BASE}${route}`);
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${OUT}/${name}-${theme}.png`, fullPage: false });
  }
  // Empty states: explore no-match search; B9 upsell needs non-designer (fresh store ok — kiki starts non-designer)
  await page.goto(`${BASE}/dashboard/explore`);
  await page.getByLabel("Search designers, styles, tags").fill("zzzz");
  await page.keyboard.press("Enter");
  await page.waitForTimeout(600);
  await page.screenshot({ path: `${OUT}/b2-explore-empty-${theme}.png` });
  // Stepper sheet (MI-10) open state
  await page.goto(`${BASE}/dashboard`);
  const asoOke = page.getByTestId("post-card").filter({ hasText: "aso-oke" });
  await asoOke.getByRole("button", { name: "Request this outfit" }).click();
  await page.waitForTimeout(500);
  await page.screenshot({ path: `${OUT}/b1-stepper-${theme}.png` });
  await ctx.close();
}
await browser.close();
console.log("done");
