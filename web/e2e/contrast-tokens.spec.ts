// Contrast-token lock (design.md §2 AA text variants) — recomputes the
// 2026-07-21 audit's failing pairs from the SERVED CSS (custom-property
// values off the live document, both themes) and asserts WCAG AA. The
// tinted-chip recipe (`text-X` on `bg-X/14`) plus plain status text must
// stay ≥4.5:1; a rendered orders-chip sweep locks the composed result.
import { expect, test, type Page } from "@playwright/test";

const AA = 4.5;

// ---- WCAG 2.x math over sRGB --------------------------------------------
type Rgb = { r: number; g: number; b: number };

function hexToRgb(hex: string): Rgb {
  const h = hex.trim().replace("#", "");
  const v =
    h.length === 3
      ? h
          .split("")
          .map((c) => c + c)
          .join("")
      : h;
  return {
    r: parseInt(v.slice(0, 2), 16),
    g: parseInt(v.slice(2, 4), 16),
    b: parseInt(v.slice(4, 6), 16),
  };
}

function luminance({ r, g, b }: Rgb): number {
  const lin = (c: number) => {
    const s = c / 255;
    return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
}

function contrast(a: Rgb, b: Rgb): number {
  const [lo, hi] = [luminance(a), luminance(b)].sort((x, y) => x - y);
  return (hi + 0.05) / (lo + 0.05);
}

/** `bg-X/nn` composited over an opaque base (what the browser paints). */
function tint(hue: Rgb, alpha: number, base: Rgb): Rgb {
  const mix = (f: number, g: number) => Math.round(alpha * f + (1 - alpha) * g);
  return {
    r: mix(hue.r, base.r),
    g: mix(hue.g, base.g),
    b: mix(hue.b, base.b),
  };
}

// ---- served-CSS readers ---------------------------------------------------
async function readTokens(
  page: Page,
  theme: "light" | "dark",
  names: string[],
): Promise<Record<string, Rgb>> {
  const raw = await page.evaluate(
    ({ t, ns }: { t: string; ns: string[] }) => {
      document.documentElement.setAttribute("data-theme", t);
      const cs = getComputedStyle(document.documentElement);
      return Object.fromEntries(
        ns.map((n) => [n, cs.getPropertyValue(n).trim()]),
      );
    },
    { t: theme, ns: names },
  );
  const out: Record<string, Rgb> = {};
  for (const [name, value] of Object.entries(raw)) {
    // The dev server may serve minified hex (#fff) — accept both forms.
    expect(value, `${name} is declared in the served CSS (${theme})`).toMatch(
      /^#([0-9a-f]{3}|[0-9a-f]{6})$/i,
    );
    out[name] = hexToRgb(value);
  }
  return out;
}

const TOKENS = [
  "--ap-bg",
  "--ap-bg-elev",
  "--ap-on-accent",
  "--ap-link",
  "--ap-success",
  "--ap-warn",
  "--ap-error",
  "--ap-text-2",
  "--ap-accent-text",
  "--ap-success-text",
  "--ap-warn-text",
  "--ap-text-2-text",
];

test("§2 token pairs recomputed from served CSS clear WCAG AA in both themes", async ({
  page,
}) => {
  await page.goto("/");
  for (const theme of ["light", "dark"] as const) {
    const t = await readTokens(page, theme, TOKENS);
    const cases: Array<{ name: string; fg: Rgb; bg: Rgb }> = [];

    // The chip/pill recipe: `-text` label on the base hue's 14% tint
    // (StatusPill, ModerationQueueRow, CaptureResults, MeasurementCard),
    // over both surfaces. `error`/`link` labels stay on the base hue —
    // locked here so a base-value drift can't silently break them.
    const chip: Array<[string, string]> = [
      ["--ap-success-text", "--ap-success"],
      ["--ap-warn-text", "--ap-warn"],
      ["--ap-text-2-text", "--ap-text-2"],
      ["--ap-error", "--ap-error"],
      ["--ap-link", "--ap-link"],
    ];
    for (const [fg, hue] of chip) {
      for (const surface of ["--ap-bg", "--ap-bg-elev"] as const) {
        cases.push({
          name: `${fg} on ${hue}/14 over ${surface}`,
          fg: t[fg],
          bg: tint(t[hue], 0.14, t[surface]),
        });
      }
    }

    // Banner action links: tone text on the tone's 10% tint over bg.
    for (const [fg, hue] of [
      ["--ap-warn-text", "--ap-warn"],
      ["--ap-success-text", "--ap-success"],
      ["--ap-error", "--ap-error"],
      ["--ap-link", "--ap-link"],
    ] as const) {
      cases.push({
        name: `${fg} on ${hue}/10 over --ap-bg (Banner action)`,
        fg: t[fg],
        bg: tint(t[hue], 0.1, t["--ap-bg"]),
      });
    }

    // Plain status/accent text on the page surfaces.
    for (const fg of [
      "--ap-warn-text",
      "--ap-success-text",
      "--ap-text-2-text",
      "--ap-accent-text",
    ]) {
      for (const surface of ["--ap-bg", "--ap-bg-elev"] as const) {
        cases.push({ name: `${fg} on ${surface}`, fg: t[fg], bg: t[surface] });
      }
    }

    for (const c of cases) {
      const ratio = contrast(c.fg, c.bg);
      expect
        .soft(ratio, `${theme}: ${c.name} ≥ ${AA} (got ${ratio.toFixed(2)})`)
        .toBeGreaterThanOrEqual(AA);
    }
  }

  // The final-CTA pill is a fixed-light locale: Light `accent-text` on
  // `on-accent` white in BOTH themes (the section pins data-theme).
  const light = await readTokens(page, "light", TOKENS);
  const pill = contrast(light["--ap-accent-text"], light["--ap-on-accent"]);
  expect(
    pill,
    `light --ap-accent-text on --ap-on-accent (final-CTA pill) ≥ ${AA}`,
  ).toBeGreaterThanOrEqual(AA);
});

// ---- rendered surface: the audited orders chips, light theme --------------
test("orders status chips render ≥4.5:1 in light theme (served pages)", async ({
  page,
}) => {
  await page.goto("/signin");
  await page.getByRole("button", { name: /continue with google/i }).click();
  await page.waitForURL("**/dashboard");
  await page.goto("/dashboard/orders");
  await page.evaluate(() =>
    document.documentElement.setAttribute("data-theme", "light"),
  );

  // StatusPill only (RequestCard stamps data-status on the whole card).
  const pills = page.locator("span.rounded-pill[data-status]");
  await pills.first().waitFor({ state: "visible", timeout: 15_000 });
  const count = await pills.count();
  expect(count, "orders page renders status chips").toBeGreaterThan(0);

  for (let i = 0; i < count; i++) {
    const pill = pills.nth(i);
    const result = await pill.evaluate((el) => {
      type C = { r: number; g: number; b: number; a: number };
      const parse = (s: string): C => {
        const m = s.match(/rgba?\(([^)]+)\)/);
        if (!m) return { r: 0, g: 0, b: 0, a: 0 };
        const [r, g, b, a = "1"] = m[1].split(/[,/ ]+/).filter(Boolean);
        return {
          r: Number(r),
          g: Number(g),
          b: Number(b),
          a: Number(a),
        };
      };
      const over = (top: C, base: C): C => ({
        r: top.r * top.a + base.r * (1 - top.a),
        g: top.g * top.a + base.g * (1 - top.a),
        b: top.b * top.a + base.b * (1 - top.a),
        a: 1,
      });
      // Effective backdrop: walk up compositing every non-transparent
      // background until an opaque one (body carries the page bg).
      const layers: C[] = [];
      let node: Element | null = el;
      let opaque = false;
      while (node) {
        const bg = parse(getComputedStyle(node).backgroundColor);
        if (bg.a > 0) layers.push(bg);
        if (bg.a >= 1) {
          opaque = true;
          break;
        }
        node = node.parentElement;
      }
      if (!opaque)
        layers.push(parse(getComputedStyle(document.body).backgroundColor));
      let backdrop = layers[layers.length - 1];
      for (let j = layers.length - 2; j >= 0; j--) {
        backdrop = over(layers[j], backdrop);
      }
      const fg = parse(getComputedStyle(el).color);
      if (fg.a < 1) return null; // gradient-clip "fresh" pill — text is a fill
      const lum = (c: C) => {
        const lin = (v: number) => {
          const s = v / 255;
          return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
        };
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
      };
      const [lo, hi] = [lum(fg), lum(backdrop)].sort((x, y) => x - y);
      return {
        status: el.getAttribute("data-status"),
        ratio: (hi + 0.05) / (lo + 0.05),
      };
    });
    if (result === null) continue;
    expect
      .soft(
        result.ratio,
        `[data-status="${result.status}"] renders ≥ ${AA} (got ${result.ratio.toFixed(2)})`,
      )
      .toBeGreaterThanOrEqual(AA);
  }
});
