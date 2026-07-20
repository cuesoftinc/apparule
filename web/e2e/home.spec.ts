// "Marketing site" journey (design.md §8.4, web-implementation.md §7):
// Part A scroll — every section renders — plus the FAQ accordion, the
// Try Cloud / Sign in CTA handoff into /signin, and the theme toggle.
// Runs in TEST_MODE: the A7b star badge deterministically keeps its
// neutral "Star" label (no third-party fetch in CI).
import { expect, test } from "@playwright/test";

test.describe("Marketing site — home page", () => {
  test("all Part A sections render top to bottom", async ({ page }) => {
    await page.goto("/");

    // A2 hero
    await expect(
      page.getByRole("heading", { name: "Two photos. A perfect fit." }),
    ).toBeVisible();
    await expect(page.getByTestId("hero-phone")).toBeVisible();

    // A1 nav — GitHub renders as the compact star badge, neutral in
    // TEST_MODE (accuracy standard); A7b carries its own badge
    await expect(page.getByTestId("star-badge")).toContainText("Star");
    await expect(page.getByTestId("dev-star-badge")).toContainText("Star");

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
      page.getByText("Open-source · MIT licensed · Self-host in one line"),
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
    await expect(page.getByText(/auto-deleted within 30 days/)).toBeVisible();

    // deep link opens the linked row
    await page.goto("/#faq-5");
    await expect(
      page.getByRole("button", { name: "What license is Apparule under?" }),
    ).toHaveAttribute("aria-expanded", "true");
  });

  test("Try Cloud CTA hands off to /signin", async ({ page }) => {
    await page.goto("/");
    // Parity canon: the nav CTA is Sign in — Try Cloud hands off from the
    // hero (and A9c/comparison) instead.
    await page.getByRole("button", { name: "Try Cloud" }).first().click();
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

  test("theme toggle cycles light → dark → system", async ({ page }) => {
    await page.goto("/");
    const html = page.locator("html");

    // Fresh visit = light (key absent), the design default.
    await expect(html).toHaveAttribute("data-theme", "light");
    expect(
      await page.evaluate(() => window.localStorage.getItem("apparule.theme")),
    ).toBeNull();
    await page
      .getByRole("button", { name: "Theme: light — switch to dark" })
      .click();
    await expect(html).toHaveAttribute("data-theme", "dark");

    await page
      .getByRole("button", { name: "Theme: dark — switch to system" })
      .click();
    // "system" is now stored explicitly (not key-absent); resolved from
    // the OS (light here).
    expect(
      await page.evaluate(() => window.localStorage.getItem("apparule.theme")),
    ).toBe("system");
    await expect(html).toHaveAttribute("data-theme", "light");

    // System mode follows an OS-level scheme flip without a reload.
    await page.emulateMedia({ colorScheme: "dark" });
    await expect(html).toHaveAttribute("data-theme", "dark");
    await page.emulateMedia({ colorScheme: "light" });
    await expect(html).toHaveAttribute("data-theme", "light");

    // Fourth press returns to light, closing the cycle.
    await page
      .getByRole("button", { name: "Theme: system — switch to light" })
      .click();
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

// W2.1 live-QA regressions (live-site sweep, design.md container canon
// [Decided 2026-07-19]): one 1080 content column (x 180–1260 at 1440),
// no horizontal overflow, single-landmark semantics, circular avatars.
test.describe("W2.1 live-QA — containers, landmarks, avatars", () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  test("one main / banner nav / footer / h1 per page", async ({ page }) => {
    await page.goto("/");
    expect(await page.locator("main").count()).toBe(1);
    expect(await page.locator("body > div > nav").count()).toBe(1);
    expect(await page.getByRole("contentinfo").count()).toBe(1);
    expect(await page.locator("h1").count()).toBe(1);
  });

  test("every section, the nav and the footer share the 1080 content column", async ({
    page,
  }) => {
    await page.goto("/");
    const edges = await page.evaluate(() => {
      const vw = document.documentElement.clientWidth;
      const measured: { label: string; left: number; right: number }[] = [];
      for (const section of document.querySelectorAll("main > section")) {
        const rect = section.getBoundingClientRect();
        const label = section.getAttribute("aria-labelledby") ?? "section";
        if (rect.width >= vw - 1) {
          // full-bleed band — its inner div carries the column
          const inner = section.firstElementChild!.getBoundingClientRect();
          measured.push({ label, left: inner.x, right: inner.right });
        } else {
          // px-6 sections: content column = box minus the 24px gutters
          measured.push({ label, left: rect.x + 24, right: rect.right - 24 });
        }
      }
      const navInner = document
        .querySelector("body > div > nav > div")!
        .getBoundingClientRect();
      measured.push({ label: "nav", left: navInner.x, right: navInner.right });
      const footInner = document
        .querySelector("footer > div")!
        .getBoundingClientRect();
      measured.push({
        label: "footer",
        left: footInner.x,
        right: footInner.right,
      });
      return measured;
    });
    for (const { label, left, right } of edges) {
      expect(left, `${label} left edge`).toBeGreaterThan(179);
      expect(left, `${label} left edge`).toBeLessThan(181);
      expect(right, `${label} right edge`).toBeGreaterThan(1259);
      expect(right, `${label} right edge`).toBeLessThan(1261);
    }
  });

  test("no horizontal overflow at 1440 and 390", async ({ page }) => {
    for (const width of [1440, 390]) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto("/");
      const overflow = await page.evaluate(() => ({
        doc: document.documentElement.scrollWidth,
        client: document.documentElement.clientWidth,
      }));
      expect(overflow.doc, `scrollWidth at ${width}`).toBe(overflow.client);
      // the walkthrough rail must scroll inside its box, never overflow it
      const rail = page.getByTestId("walkthrough-rail");
      const fits = await rail.evaluate(
        (el) => el.getBoundingClientRect().right <= window.innerWidth,
      );
      expect(fits, `walkthrough rail inside viewport at ${width}`).toBe(true);
    }
  });

  test("avatar photos render as true circles (no lozenges)", async ({
    page,
  }) => {
    await page.goto("/");
    // let the hero demo loop + reveal-on-scroll content mount
    await page.getByTestId("hero-phone").waitFor();
    const ratios = await page.evaluate(() => {
      const out: { src: string; ratio: number }[] = [];
      for (const img of document.querySelectorAll<HTMLImageElement>(
        "[data-ring] img",
      )) {
        const rect = img.getBoundingClientRect();
        if (rect.width === 0) continue;
        out.push({
          src: (img.currentSrc || img.src).split("/").pop() ?? "",
          ratio: rect.width / rect.height,
        });
      }
      return out;
    });
    expect(ratios.length).toBeGreaterThan(0);
    for (const { src, ratio } of ratios) {
      expect(Math.abs(ratio - 1), `avatar ${src} aspect ratio`).toBeLessThan(
        0.05,
      );
    }
  });
});

// System-QA regressions (2026-07-19).
test.describe("system QA regressions", () => {
  test("unknown routes render the branded 404, not the Next.js default", async ({
    page,
  }) => {
    await page.goto("/definitely-not-a-page");
    await expect(
      page.getByRole("heading", { name: "This page doesn't exist" }),
    ).toBeVisible();
    await expect(
      page.getByRole("link", { name: "Back to Apparule" }),
    ).toBeVisible();
    await expect(page.getByText("This page could not be found")).toHaveCount(0);
  });

  test("comparison-table CTAs keep to one line at 390 (no pill wrap)", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    const cta = page.getByRole("button", { name: "Start on Cloud" });
    await cta.scrollIntoViewIfNeeded();
    for (const name of ["Start on Cloud", "Self-host it"]) {
      const box = await page.getByRole("button", { name }).boundingBox();
      expect(box, `${name} rendered`).not.toBeNull();
      // sm buttons are h-9 (36px) — a wrapped label pushes past the pill
      expect(box!.height, `${name} single-line height`).toBeLessThanOrEqual(38);
    }
  });
});

// Marketing nav/footer link-parity canon (SKILL.md, ratified 2026-07-19):
// the exact link sets and verified URLs, asserted on the live DOM.
test.describe("nav/footer parity canon", () => {
  test("nav carries the four canon links + the Sign in CTA", async ({
    page,
  }) => {
    await page.goto("/");
    const nav = page.getByRole("navigation", { name: "Home" });
    await expect(nav.getByRole("link", { name: "Features" })).toHaveAttribute(
      "href",
      "#product",
    );
    await expect(
      nav.getByRole("link", { name: "For designers" }),
    ).toHaveAttribute("href", "#designers");
    await expect(nav.getByRole("link", { name: "Docs" })).toHaveAttribute(
      "href",
      "https://cuesoft.gitbook.io/apparule",
    );
    // GitHub = compact star badge (canon revision)
    const badge = nav.getByRole("link", {
      name: "Star cuesoftinc/apparule on GitHub",
    });
    await expect(badge).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule",
    );
    await expect(badge).toContainText("Star");
    await expect(nav.getByRole("link", { name: "Sign in" })).toHaveAttribute(
      "href",
      "/signin",
    );
    // Try Cloud is the one primary CTA and hands off to /signin
    await nav.getByRole("button", { name: "Try Cloud" }).click();
    await page.waitForURL("**/signin");
  });

  test("footer carries the canon columns, URLs and legal bar", async ({
    page,
  }) => {
    await page.goto("/");
    const footer = page.locator("footer");
    const canon: [string, string][] = [
      ["Docs", "https://cuesoft.gitbook.io/apparule"],
      ["Quickstart", "https://cuesoft.gitbook.io/apparule/setup"],
      // In-product Scalar reference (F0-8) — /docs/api renders the spec.
      ["API reference", "/docs/api"],
      [
        "Self-host guide",
        "https://cuesoft.gitbook.io/apparule/system/deployment",
      ],
      ["GitHub", "https://github.com/cuesoftinc/apparule"],
      ["Discord", "https://discord.gg/CDfZxxrxbb"],
      ["Roadmap", "https://cuesoft.gitbook.io/apparule/product/roadmap"],
      ["CueLABS™", "https://cuelabs.cuesoft.io"],
      ["Privacy", "https://privacy.cuesoft.io"],
      ["Terms", "https://terms.cuesoft.io"],
      ["Status", "https://status.cuesoft.io"],
      ["Cuesoft Inc.", "https://cuesoft.io"],
      [
        "MIT License",
        "https://github.com/cuesoftinc/apparule/blob/main/LICENSE",
      ],
    ];
    for (const [name, href] of canon) {
      await expect(
        footer.getByRole("link", { name, exact: true }),
        `footer link ${name}`,
      ).toHaveAttribute("href", href);
    }
    await expect(
      footer.getByRole("link", { name: /Security policy/ }),
    ).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule/blob/main/SECURITY.md",
    );
    await expect(
      footer.getByText(/© Cuesoft Inc\. 2026\. Apparule\. CueLABS™ Division\./),
    ).toBeVisible();
    await expect(
      footer.getByRole("link", { name: "CueLABS™ Division" }),
    ).toHaveAttribute("href", "https://cuelabs.cuesoft.io");
    await expect(footer.getByLabel("Language")).toBeVisible();
    await expect(footer.getByText("Contributing")).toHaveCount(0);
    await expect(footer.getByText("Good first issues")).toHaveCount(0);
  });

  test("below md the canon links live in a hamburger disclosure (390)", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    const nav = page.getByRole("navigation", { name: "Home" });

    // the four text links are collapsed…
    await expect(nav.getByRole("link", { name: "Features" })).toBeHidden();
    const trigger = page.getByTestId("nav-menu-button");
    await expect(trigger).toBeVisible();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");

    // …and the disclosure panel carries all four canonical hrefs
    await trigger.click();
    await expect(trigger).toHaveAttribute("aria-expanded", "true");
    const panel = page.getByTestId("nav-menu-panel");
    await expect(panel).toBeVisible();
    const canon: [string, string][] = [
      ["Features", "#product"],
      ["For designers", "#designers"],
      ["Docs", "https://cuesoft.gitbook.io/apparule"],
      ["Sign in", "/signin"],
    ];
    for (const [name, href] of canon) {
      await expect(
        panel.getByRole("link", { name, exact: true }),
        `menu link ${name}`,
      ).toHaveAttribute("href", href);
    }

    // GitHub renders as the same compact star badge as desktop (Codex P2:
    // the panel used to fall back to a plain "GitHub" text link and never
    // read the live count) — neutral "Star" in TEST_MODE (no third-party
    // fetch in CI, accuracy standard).
    const panelBadge = panel.getByRole("link", {
      name: "Star cuesoftinc/apparule on GitHub",
    });
    await expect(panelBadge).toHaveAttribute(
      "href",
      "https://github.com/cuesoftinc/apparule",
    );
    await expect(panelBadge).toContainText("Star");

    // [Revised 2026-07-19 canon] Try Cloud stays visible on the BAR
    // beside the hamburger; the panel carries no duplicate row.
    await expect(nav.getByRole("button", { name: "Try Cloud" })).toBeVisible();
    await expect(panel.getByRole("button", { name: "Try Cloud" })).toHaveCount(
      0,
    );

    // the theme toggle works from inside the panel (fresh boot is light,
    // the design default; light → dark → system)
    await panel.getByRole("button", { name: /^Theme: light/ }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await panel.getByRole("button", { name: /^Theme: dark/ }).click();
    // "system" is stored explicitly; resolved from the OS (light here).
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");

    // a link click closes the disclosure
    await panel.getByRole("link", { name: "Features" }).click();
    await expect(page.getByTestId("nav-menu-panel")).toBeHidden();
    await expect(trigger).toHaveAttribute("aria-expanded", "false");
  });

  test("below md the footer stacks per the canon: full-width brand, 2-col grid, grouped legal cluster (390)", async ({
    page,
  }) => {
    // Footer mobile structure canon (SKILL.md, pinned 2026-07-19): brand
    // block full-width first · 4 link columns in a 2-col grid · divider ·
    // legal bar with © first + one grouped wrapping utilities cluster.
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    const footer = page.locator("footer");
    await footer.scrollIntoViewIfNeeded();
    const heading = (name: string) =>
      footer.getByRole("heading", { name, exact: true });
    const boxOf = async (locator: ReturnType<typeof heading>) => {
      const box = await locator.boundingBox();
      expect(box).not.toBeNull();
      return box!;
    };
    // 2-col grid: Product+Docs share a row, Community+Legal the next
    const product = await boxOf(heading("Product"));
    const docs = await boxOf(heading("Docs"));
    const community = await boxOf(heading("Community"));
    const legal = await boxOf(heading("Legal"));
    expect(Math.abs(product.y - docs.y)).toBeLessThanOrEqual(1);
    expect(Math.abs(community.y - legal.y)).toBeLessThanOrEqual(1);
    expect(product.y).toBeLessThan(community.y);
    // brand block sits first and spans the full container (col-span-2)
    const brand = await boxOf(
      footer.getByText(/AI body measurement and made-to-measure fashion/),
    );
    expect(brand.y).toBeLessThan(product.y);
    expect(brand.width).toBeGreaterThan(300);
    // legal bar: © line first; Security policy + language selector sit in
    // one grouped wrapping cluster after it
    const copyright = await boxOf(footer.getByText(/©/).first());
    const utilities = await boxOf(page.getByTestId("legal-bar-utilities"));
    expect(copyright.y).toBeLessThan(utilities.y + utilities.height);
    const security = await boxOf(
      footer.getByRole("link", { name: "Security policy" }),
    );
    const language = await boxOf(footer.getByLabel("Language"));
    expect(
      Math.abs(
        security.y + security.height / 2 - (language.y + language.height / 2),
      ),
    ).toBeLessThanOrEqual(4);
  });

  test("theme toggle flips and persists on home and dashboard", async ({
    page,
  }) => {
    // marketing surface: fresh boot is light (the design default, key
    // absent) → dark, persisted across reload
    await page.goto("/");
    await page.getByRole("button", { name: /^Theme: light/ }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await page.reload();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");

    // dashboard surface (same apparule.theme key via NavRail toggle):
    // dark → system now stores "system" explicitly; resolved follows the
    // OS again.
    await page.goto("/signin");
    await page.getByRole("button", { name: /continue with google/i }).click();
    await page.waitForURL("**/dashboard");
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await page.getByRole("button", { name: /^Theme: dark/ }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
    const stored = await page.evaluate(() =>
      window.localStorage.getItem("apparule.theme"),
    );
    expect(stored).toBe("system");
    await page.reload();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
  });
});

// Cursor affordance [Directive 2026-07-19]: enabled interactive controls
// show the pointer (Tailwind v4 defaults buttons to cursor:default).
test.describe("cursor affordance", () => {
  test("buttons and nav links show cursor: pointer", async ({ page }) => {
    await page.goto("/");
    const buttonCursor = await page
      .getByRole("button", { name: "Try Cloud" })
      .first()
      .evaluate((el) => getComputedStyle(el).cursor);
    expect(buttonCursor).toBe("pointer");
    const linkCursor = await page
      .getByRole("navigation", { name: "Home" })
      .getByRole("link", { name: "Features" })
      .evaluate((el) => getComputedStyle(el).cursor);
    expect(linkCursor).toBe("pointer");
  });
});

// Type contract — the landing's key roles render the Figma Home frame's
// (186:2) computed type: Inter (next/font, variable — real 400/600/700, no
// synthetic bolding) at the ramp's size/line-height, with the type styles'
// tracking pinned by the utilities (Title/24 −0.25px · Display/32 −0.5px).
// Regression lock for the font-weight audit (2026-07-20).
test.describe("type contract — Figma Home frame roles", () => {
  test("per-role computed font-family/weight/size/tracking match the ramp", async ({
    page,
  }) => {
    await page.goto("/");

    const rail = page.getByTestId("walkthrough-rail");
    const roles = [
      {
        role: "hero H1 (Display/32 Bold)",
        locator: page.getByRole("heading", {
          name: "Two photos. A perfect fit.",
        }),
        weight: "700",
        size: "32px",
        lineHeight: "40px",
        letterSpacing: "-0.5px",
      },
      {
        role: "stat-band heading (Title/24 Bold)",
        locator: page.getByRole("heading", {
          name: "Made-to-measure, without the guesswork",
        }),
        weight: "700",
        size: "24px",
        lineHeight: "30px",
        letterSpacing: "-0.25px",
      },
      {
        role: "walkthrough heading (Title/24 Bold)",
        locator: page.getByRole("heading", { name: "How it works" }),
        weight: "700",
        size: "24px",
        lineHeight: "30px",
        letterSpacing: "-0.25px",
      },
      {
        role: "stat value (Display/32 Bold)",
        locator: page.getByText("±2 cm", { exact: true }),
        weight: "700",
        size: "32px",
        lineHeight: "40px",
        letterSpacing: "-0.5px",
      },
      {
        role: "stat caption (Body/14 Regular)",
        locator: page.getByText(
          "target accuracy vs a professional tape measure",
        ),
        weight: "400",
        size: "14px",
        lineHeight: "20px",
        letterSpacing: "normal",
      },
      {
        role: "step title (Body/16 Semi Bold)",
        locator: rail.getByText("Capture", { exact: true }),
        weight: "600",
        size: "16px",
        lineHeight: "22px",
        letterSpacing: "normal",
      },
      {
        role: "step caption (Body/14 Regular)",
        locator: rail.getByText(
          "Two photos — your measurements, automatically",
        ),
        weight: "400",
        size: "14px",
        lineHeight: "20px",
        letterSpacing: "normal",
      },
    ] as const;

    for (const r of roles) {
      const cs = await r.locator.evaluate((el) => {
        const s = getComputedStyle(el);
        return {
          fontFamily: s.fontFamily,
          fontWeight: s.fontWeight,
          fontSize: s.fontSize,
          lineHeight: s.lineHeight,
          letterSpacing: s.letterSpacing,
        };
      });
      expect.soft(cs.fontFamily, `${r.role} family`).toMatch(/^Inter\b/);
      expect.soft(cs.fontWeight, `${r.role} weight`).toBe(r.weight);
      expect.soft(cs.fontSize, `${r.role} size`).toBe(r.size);
      expect.soft(cs.lineHeight, `${r.role} line-height`).toBe(r.lineHeight);
      expect
        .soft(cs.letterSpacing, `${r.role} letter-spacing`)
        .toBe(r.letterSpacing);
    }

    // The ramp's three weights are real Inter faces (variable font loaded)
    // — a missing weight would silently fall back to synthetic bolding.
    const weightsReal = await page.evaluate(async () => {
      await document.fonts.ready;
      return ["400 14px Inter", "600 16px Inter", "700 24px Inter"].map((f) =>
        document.fonts.check(f),
      );
    });
    expect(weightsReal).toEqual([true, true, true]);
  });
});
