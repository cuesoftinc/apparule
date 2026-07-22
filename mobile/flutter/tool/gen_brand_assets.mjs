/**
 * gen_brand_assets.mjs — mobile brand asset generator (the mobile
 * sibling of web/scripts/generate-brand-assets.mjs; same engine idea,
 * same composition rules, so the launcher icon, splash and web favicon
 * are one brand construction with reproducible provenance).
 *
 * Generates the SOURCE PNGs flutter_launcher_icons and
 * flutter_native_splash consume (assets/brand/ — tool inputs, never
 * bundled at runtime):
 *
 *   icon_ios.png              1024×1024 full-bleed tile (iOS masks itself)
 *   icon_android_legacy.png   1024×1024 rounded tile, radius 20% (pre-26
 *                             launchers render the PNG as-is — the web
 *                             favicon construction)
 *   icon_adaptive_bg.png      1024×1024 gradient (adaptive background)
 *   icon_adaptive_fg.png      1024×1024 white A inside the 72/108 safe
 *                             zone (adaptive foreground)
 *   icon_adaptive_mono.png    same geometry, for Android 13+ themed icons
 *   splash_bg.png             1024×1024 accent gradient — the full-bleed
 *                             splash background (ratified C0 frame
 *                             534:9096; aspect-filled per screen)
 *   splash_tile.png           512×512 white A alone on transparent —
 *                             the splash center mark (Inter Bold 96dp at
 *                             the 4x/xxxhdpi source scale)
 *   splash_android12.png      1152×1152, gradient disc in the API's
 *                             768px icon circle (Android 12+ splash API
 *                             — the platform can't render a full-bleed
 *                             background image, so 12+ keeps bg + disc)
 *
 * Run manually from mobile/flutter/ (assets are committed, not built):
 *   node tool/gen_brand_assets.mjs
 * then re-run the consumers:
 *   dart run flutter_launcher_icons
 *   dart run flutter_native_splash:create
 *
 * The tile IS the brand construction (design.md §2 tokens; the web
 * favicon adjudication): white Inter-Bold "A" on the accent gradient.
 * Raw hex is intentional — assets render outside the app, so tokens are
 * quoted by VALUE with their names in comments (the web script's
 * documented-exception rule). Type renders in the BUNDLED Inter
 * (assets/fonts/Inter-Bold.ttf — no network fetch, unlike web's rsms.me
 * fallback). Chromium comes from web/node_modules (@playwright/test) —
 * run `npm ci` in web/ first if missing.
 */

import { createHash } from "node:crypto";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const flutterRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(flutterRoot, "..", "..");
const brandDir = path.join(flutterRoot, "assets", "brand");

const require = createRequire(
  path.join(repoRoot, "web", "package.json"),
);
const { chromium } = require("@playwright/test");

// design.md §2 tokens, quoted by value (names in comments).
const ACCENT_GRADIENT = "linear-gradient(135deg,#e1306c,#f77737)"; // accent (accent-start→accent-end)
const ON_ACCENT = "#ffffff"; // on-accent

// The web tile construction: Inter Bold "A" at 62% of the container's
// min side (62cqmin), centered on the accent gradient.
const markHtml = (fontSizePx) =>
  `<span style="color:${ON_ACCENT};font-weight:700;font-size:${fontSizePx}px;line-height:1;">A</span>`;

const pageShell = (fontUrl, body) => `<!doctype html>
<html><head><meta charset="utf-8"><style>
@font-face {
  font-family: "Inter";
  src: url("${fontUrl}") format("truetype");
  font-weight: 700;
  font-style: normal;
}
* { margin: 0; box-sizing: border-box; }
html, body { background: transparent; }
body { font-family: "Inter", system-ui, sans-serif; -webkit-font-smoothing: antialiased; }
.tile {
  position: fixed; top: 0; left: 0;
  display: flex; align-items: center; justify-content: center;
}
</style></head><body>${body}</body></html>`;

/** A gradient tile of [size] px with [radius] px corners and the A mark. */
const tileBody = (size, radius, fontSize = Math.round(size * 0.62)) =>
  `<div class="tile" style="width:${size}px;height:${size}px;border-radius:${radius}px;background:${ACCENT_GRADIENT};">${markHtml(fontSize)}</div>`;

/** The A mark alone on a transparent [size] canvas (adaptive layers). */
const markOnlyBody = (size, fontSize) =>
  `<div class="tile" style="width:${size}px;height:${size}px;">${markHtml(fontSize)}</div>`;

/** The gradient alone (adaptive background layer). */
const bgBody = (size) =>
  `<div class="tile" style="width:${size}px;height:${size}px;background:${ACCENT_GRADIENT};"></div>`;

/** Gradient disc of [disc] px centered on a transparent [size] canvas. */
const discBody = (size, disc) =>
  `<div class="tile" style="width:${size}px;height:${size}px;"><div class="tile" style="position:static;width:${disc}px;height:${disc}px;border-radius:50%;background:${ACCENT_GRADIENT};">${markHtml(Math.round(disc * 0.62))}</div></div>`;

async function main() {
  mkdirSync(brandDir, { recursive: true });
  const workDir = mkdtempSync(path.join(tmpdir(), "apparule-brand-"));
  const fontUrl = `file://${path.join(flutterRoot, "assets", "fonts", "Inter-Bold.ttf")}`;

  const browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: { width: 1280, height: 1280 },
    deviceScaleFactor: 1,
  });

  const shoot = async (name, body, size) => {
    const file = path.join(workDir, `${name}.html`);
    writeFileSync(file, pageShell(fontUrl, body));
    await page.goto(`file://${file}`);
    await page.evaluate(() => document.fonts.ready);
    const buf = await page.screenshot({
      clip: { x: 0, y: 0, width: size, height: size },
      omitBackground: true,
    });
    writeFileSync(path.join(brandDir, `${name}.png`), buf);
  };

  // iOS: full-bleed square — the OS applies its own mask.
  await shoot("icon_ios", tileBody(1024, 0), 1024);

  // Android pre-26 legacy launchers render the PNG as-is: the web
  // favicon tile (rounded square, radius 20%, transparent corners).
  await shoot("icon_android_legacy", tileBody(1024, Math.round(1024 * 0.2)), 1024);

  // Adaptive icon (26+): gradient background layer + white-A foreground
  // sized to the 72/108 safe zone (the A at 62% of the visible area,
  // matching the tile's optical weight).
  const adaptiveFont = Math.round(1024 * (72 / 108) * 0.62);
  await shoot("icon_adaptive_bg", bgBody(1024), 1024);
  await shoot("icon_adaptive_fg", markOnlyBody(1024, adaptiveFont), 1024);
  // Android 13+ themed icons recolor a single-alpha glyph — same layer.
  await shoot("icon_adaptive_mono", markOnlyBody(1024, adaptiveFont), 1024);

  // Splash (pre-12 Android drawables + the iOS storyboard) — the
  // ratified C0 frame (534:9096): full-bleed accent gradient with the
  // white A centered. Background: a gradient square the platforms
  // aspect-fill; mark: the A alone at Inter Bold 96dp (the source is
  // 4x, so 384px on a 512 canvas).
  await shoot("splash_bg", bgBody(1024), 1024);
  await shoot("splash_tile", markOnlyBody(512, 384), 512);

  // Android 12+ splash API: 1152×1152 with the icon inside the 768px
  // circle — a gradient disc so the OS circle crop never clips a corner.
  await shoot("splash_android12", discBody(1152, 768), 1152);

  await browser.close();

  for (const name of [
    "icon_ios",
    "icon_android_legacy",
    "icon_adaptive_bg",
    "icon_adaptive_fg",
    "icon_adaptive_mono",
    "splash_bg",
    "splash_tile",
    "splash_android12",
  ]) {
    const buf = readFileSync(path.join(brandDir, `${name}.png`));
    const sha = createHash("sha256").update(buf).digest("hex");
    console.log(`${name}.png  ${buf.length}B  sha256 ${sha}`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
