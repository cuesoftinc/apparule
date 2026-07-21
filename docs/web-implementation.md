# Apparule — Web Implementation Standard

> How `web/` gets built: the **CueLABS™ Web Implementation Standard**
> (ratified 2026-07-18, org-wide **[Directive]**) carried in full, plus the
> Apparule-specific addendum — stage plan, token mapping, route map,
> TEST_MODE contract, mock server, test strategy, legacy policy. Markers as
> in [design.md](design.md): **[Directive]** = user-stated direction,
> **[Proposed]** = ratifiable decision, **[Decided <date>]** = ratified.
> Companion contracts: [engineering.md](engineering.md) (errors, authz,
> limits), [design.md](design.md) (tokens, components, MI catalog),
> [pages.md](pages.md) (screens), [api.md](api.md) (surface).

## 1. The standard (ecosystem, shared across the three products)

- **Stack**: Next.js 16 App Router + React 19 + TypeScript; Tailwind maps to
  the token CSS variables (§3). Apparule's `web/` carries no legacy UI kit —
  new-system components are token/Tailwind-based from day one.
- **Design tokens**: `web/src/design/tokens.css` — CSS custom properties
  mirroring design.md §2 exactly (light on `:root`, dark on
  `[data-theme="dark"]`, honoring `prefers-color-scheme` with manual
  override; spacing 4–64; radii; durations + easings; z layers; on-accent).
  **No raw hex in components** — the same rule as Figma (design.md §7);
  documented exceptions carry a code comment.
- **Components**: `web/src/components/ui/<Name>.tsx` — one module per Figma
  component set, named exactly as the set (PascalCase, design.md §8.1 naming
  standards); props mirror the variant axes (`kind`/`size`/`state`/…);
  microinteractions from design.md §4 implemented with duration/easing
  tokens and `prefers-reduced-motion` fallbacks (design.md §5); each
  component unit-tested.
- **MVC**: models = `web/src/models/` (typed entities per
  [data-model.md](data-model.md) + repositories per
  [api.md](api.md)/[openapi.yaml](api/openapi.yaml) — the **only** layer
  that talks to the network); controllers = `web/src/controllers/`
  (feature-scoped hooks/orchestration, own all state; views never fetch);
  views = `web/src/app/**` routes + composed components, render-only.
- **TEST_MODE**: `NEXT_PUBLIC_TEST_MODE=1` → GoogleAuthButton navigates
  straight to the dashboard (no Firebase), and the API client targets the
  in-app mock server (§5). Auth sits behind an `AuthProvider` interface
  (`TestModeAuthProvider` now; `FirebaseAuthProvider` added at
  backend-integration time — X-1 Google-only either way,
  [flows/auth.md](flows/auth.md)).
- **Mock server**: Next route handlers under `web/src/app/api/mock/*`
  implementing the documented API surface the web needs (paths, snake_case
  error codes, and taxonomies from api.md/openapi.yaml), backed by a seeded
  in-memory store with full CRUD (dev-persistent via a module singleton);
  seed data = the docs-coherent Figma dataset (§6) so the app boots looking
  like the designs. Contract types shared with models.
- **Tests**: Vitest + Testing Library for unit/integration (components,
  controllers, mock handlers); Playwright e2e mirroring the design.md §8.4
  prototype journeys, run in TEST_MODE against the mock server; both wired
  into CI build+test (X-6: merge-to-main never deploys).
- **Legacy / dead-code policy**: before replacement, legacy trees are
  `git mv`-ed into `web/src/legacy/` (structure preserved, excluded from
  build & routing) — live paths carry zero dead code; after the replacement
  passes QA + Playwright, the legacy subtree is deleted in a dedicated
  `chore(web): retire legacy <area>` PR. No dead code outside `src/legacy/`,
  ever; `src/legacy/` itself trends to empty. Apparule's application of the
  policy: §8.
- **Process**: stages W0 → W3 (§2), PR per stage; conventional commits; QA
  loops evaluate the implementation against the Figma file (tokens,
  geometry, states, interactions) before a stage closes; docs + the org
  SKILL.md updated with every deviation.
- **Component reuse policy [Decided 2026-07-18]**: pixel-fidelity to the
  Figma file wins. All **visual** components are built in-house from the
  token layer — no styled component kits in new code (no MUI, no
  shadcn/DaisyUI skins) and no chart libraries (sparklines and any future
  charts are bespoke SVG built to the Figma specs — e.g. the
  MeasurementCard sparkline). Reuse is allowed only where it is invisible:
  headless behavior primitives (Radix/Base UI class — dialog, popover,
  select, tabs, switch, checkbox, tooltip, accordion semantics with focus
  traps, keyboard nav, ARIA), positioning engines (Floating UI),
  `lucide-react` (the design system's own icon set, design.md §2 — matches
  by construction; brand glyphs like the Google 'G' and GitHub mark as
  local SVGs per the §8.1 icon note), and math/format utilities (d3-scale,
  date-fns, clsx). Fidelity is verified against the Figma file in the stage
  QA loops (screenshot comparison + token/geometry checks).

## 2. Stage plan — W0 foundations → W3 dashboards

One PR per stage; a stage closes only after its QA loop against the Figma
file passes (screenshot comparison + token/geometry/state checks against the
Style Guide, component sets, and screen frames — the same standard as the
design-phase QA loops, design.md §8).

| Stage | Scope | Closes when |
| --- | --- | --- |
| **W0 Foundations** | `tokens.css` (§3) + Tailwind mapping · MVC skeleton (`models/`, `controllers/`, `components/ui/`) · `AuthProvider` interface + `TestModeAuthProvider` · mock server + seed dataset (§5–6) · Vitest + Playwright harnesses wired into CI build+test | tokens render both themes correctly vs the Style Guide page; TEST_MODE boots to a stubbed dashboard against the mock server; CI green |
| **W1 Components** | `components/ui/*` per the design.md §8.1 build order (atoms → molecules → cards) and §8.2/§8.2b contract rows, web-applicable MI specs (MI-1…MI-19; MI-20 haptics is mobile-only) · unit tests per component | every built component passes QA vs its Figma component set (variants, states, both themes, motion specs) |
| **W2 Home** **[Done 2026-07-19, PR #87]** | Part A screens (§4): A1–A10 + iteration rows A4b/A7b/A7c/A9b/A9c · analytics events to Upstat (D2: `page_view`, `demo_start`, `github_click`, `try_cloud_click`, `self_host_click`) · live GitHub star fetch (A1/A7b) | QA vs the Stage-5 Figma page; Playwright covers the "Marketing site" §8.4 flow incl. the CTA handoff |
| **W3 Dashboards** **[Done 2026-07-19, PR #91]** | Part B routes (§4): B1–B9 + B7a · feature controllers · request stepper, payments UI, vault, moderation | QA vs the Stage-4 Figma frames + prototype flows; Playwright covers the §8.4 dashboard journeys (§7) |

**W2 as-built notes (2026-07-19, PR #87):**

- Hero phone mock is a live composed component loop (pauses on hover and on
  `prefers-reduced-motion`), not a static image or video asset.
- Walkthrough and feature-deep-dive thumbnails are composed mini-previews
  (`MiniScreen`) rendered from real components, not raster screen exports.
- FAQ answers 2–5 are authored to the pages.md contract.
- The theme toggle lives in `MarketingNav`, not a standalone control.
- Analytics events land on a TEST_MODE queue behind an `AnalyticsTransport`
  seam — the Upstat transport wires in at D2.
- The GitHub star badge renders neutral first, then resolves via a runtime
  fetch (no build-time count).
- Registry `ComparisonTable`, `CommunityCard`, and `WalkthroughStep` were
  rebuilt to the enriched Figma masters during the W2 QA loop.
- Section components live in `web/src/components/home/` (canon).

**W2.1 live-QA as-built notes (2026-07-19, PR #90):** a live-site Playwright
sweep of the deployed home page against the design.md **[Decided
2026-07-19]** 1080-content-column canon, fixing what the QA loop's local
screenshot compares had missed:

- Avatar circularity root cause: Tailwind preflight's `img { height: auto }`
  overrode the Next `<Image>` height attribute, so ringed avatars rendered
  at the source photo's aspect ratio instead of a circle. `Avatar` now gives
  the photo an explicit square CSS box (`object-cover`) and draws the ring
  as a separate stroke with a clear gap, per the Figma master.
- The 1080 content column is enforced pixel-exact, not eyeballed:
  `web/e2e/home.spec.ts` asserts every home section, `MarketingNav`, and
  `MarketingFooter` share the column within ±1px at 1440/390/2400 widths.
- Decorative dashboard thumbnails (`MiniScreen`, rendered via real
  `NavRail`/`TabBar` links for visual fidelity) carry `prefetch={false}` so
  viewport prefetch on the landing page doesn't fire live 404s against
  unauthenticated `/dashboard/*` routes.
- `body` and `:focus-visible` in `globals.css` were bare element-level
  selectors that could beat `@layer` rules (the class of bug that broke
  production on a sibling repo); both now sit inside `@layer base`.
- Semantic audit (landmarks, heading hierarchy, list markup) came back
  clean and is now locked in with e2e assertions rather than re-checked
  manually.

**System-QA as-built notes (2026-07-19, PR #93):** the full-system QA pass
(final web-phase gate) walked every §8.4 journey on the TEST_MODE prod
build at 1440/390, light/dark/reduced-motion, and fixed what it found:

- The quote sheet's due-date calendar was unusable — `DateInput`'s popover
  sat on the z-20 dropdown layer under the z-40 Sheet. It now uses the
  sheet layer, the same in-sheet fix `Select` received in W3; treat
  "overlay opened from inside a Sheet" as z-40 by default.
- Branded `not-found.tsx` / `error.tsx` (EmptyState anatomy) replace the
  Next.js defaults.
- `Button` and `Chip` carry `whitespace-nowrap` — pill labels never wrap
  (the 390px comparison CTAs were the live repro).
- `formatAgoPhrase` ("2d ago" / "just now" / "on 22 May") is the single
  relative-timestamp formatter — no hand-appended " ago" templates.
- MI-3's first-save "Saved to your looks" toast now exists (once per
  browser, Toast gained an optional trailing link).
- Seed coherence: designer `posts_count` is test-locked to the actually
  seeded posts; payout-SLA copy aligned across PaymentBox/EarningsView.
- 390px overflow fixes (order-detail grid, moderation actions, profile
  stats) are e2e-gated across all dashboard routes.

**Link-parity as-built notes (2026-07-19):** the org "Marketing nav,
footer & theme parity canon" (SKILL.md) applied — nav is four links,
Features · For designers · Docs · GitHub, with GitHub rendered as the
compact star badge (live count from the cached fetch seam shared with
A7b; TEST_MODE and failures keep the neutral "Star" label), + theme
toggle + a **Sign in** text link + the **Try Cloud** gradient primary CTA
(→ /signin); nav and hero/A9c/comparison CTAs fire `try_cloud_click`.
Footer is brand block + Product/Docs/Community/**Legal** columns (4/4/4/3
links) + the verbatim legal bar ("© Cuesoft Inc. 2026. Apparule. CueLABS™
Division. MIT License." — Cuesoft Inc., CueLABS™ Division and MIT License
are inline links) with the security-policy affordance and language
selector. All external URLs are the verified-200 canon targets
(`cuesoft.gitbook.io/apparule/*`, `discord.gg/CDfZxxrxbb`,
`cuelabs.cuesoft.io`, `privacy/terms/status.cuesoft.io`); Discord channel
copy is `#apparule-lab`. Below md the bar keeps the Try
Cloud CTA beside the hamburger (aria-expanded trigger); the panel
carries the 4 links + ThemeToggle + Sign in. [Revised 2026-07-19] Enabled interactive
controls show `cursor: pointer` via one base-layer rule in `globals.css`
(design.md §2 cursor-affordance foundation); removable Chips are a pill
of two real buttons (label + keyboard-reachable ✕). Playwright asserts
the exact hrefs on nav + footer, walks every canonical href through the
390 disclosure, covers theme flip+persist on both surfaces, and pins the
pointer cursor on controls.

**W3 as-built notes (2026-07-19, PR #91):**

- Every Part B route (§4) is a fully working screen assembled from the W1
  component registry over the mock server, MVC held throughout: feed (B1),
  explore (B2), orders + detail (B3), measurement vault (B4), create /
  composer with creator upsell (B5), profiles (B6), settings + the
  notifications/privacy/account sub-screens (B7), moderation queue (B7a),
  designer onboarding + KYC (B8), and earnings (B9).
- TEST_MODE dashboard journeys live in `web/e2e/dashboard.spec.ts`: a
  semantic-landmarks sweep across all 15 dashboard screens, plus the §8.4
  journeys — feed like/save/follow → request stepper → quote → pay →
  escrow-held → thread reply; all ten order-lifecycle states rendering
  from seed; vault webcam QC-failure → retake → capture → save, with
  history delete; creator upsell → onboarding (Paystack mismatch + resolve)
  → publish → profile grid; notification-preference persistence + consent
  history; moderation dismiss; dispute-freeze and confirm-delivery-release;
  and decline-with-reason + itemized earnings payout.
- The legacy-quarantine boundary is gated two ways: an eslint
  `no-restricted-imports` rule scoped to `src/legacy/**` (lint-time), and
  `scripts/check-boundaries.mjs` — the org-shared boundary gate (byte-identical
  across apparule/expendit/upstat, per-repo rule lists inside), wired into
  `npm run lint` via `check:boundaries`.
- `src/legacy/` is currently empty; no live path imports from it (the
  boundary gates above keep it that way).
- Semantic-HTML landmarks (one `<main>`, one `nav[aria-label="Primary"]`)
  are enforced by e2e across all 15 dashboard screens, not spot-checked.

**Mobile-responsiveness as-built notes (2026-07-19, PR #101):** the P1
mobile pass **[Directive]** — home and every dashboard route render fully
inside the mobile boundary at 390 (768 sanity); the document never
side-scrolls, and wide elements scroll within their own containers:

- `web/e2e/mobile-responsive.spec.ts` sweeps all 19 routes (public +
  dashboard, settings sub-screens and order detail included) asserting
  `document.scrollWidth <= viewport` at 390 AND 768, plus wide-element
  containment: any `table`/`pre`/`code` wider than the viewport must sit
  inside an `overflow-x: auto` container that itself fits.
- The A9 comparison table scrolls horizontally within its card below its
  min-content width (the "Self-host it" CTA was clipped at 390).
- One `@layer base` rule — `fieldset { min-inline-size: 0 }` — normalizes
  the fieldset default that defeats child truncation (the request
  stepper's snapshot picker overflowed the 390 viewport this way).
- Thread image attachments carry `max-w-full` so a fixed-width bubble
  image never crops at narrow widths.
- Interactive overlays are part of the audited surface: stepper steps
  1–3, quote sheet + due-date picker, decline/dispute/confirm-delivery,
  capture and history sheets, explore post modal, followers sheet.

**UX & demo-realism as-built notes (2026-07-19, PR #102):** the P1 UX +
realism pass **[Directive]** — the seed simulates actual user interaction:

- Six community accounts widen the cast; comments, follower sheets and
  notification actors come from multiple users at a plausible cadence
  (35m/6h/20h/2.8d spread, no synthetic same-day clusters).
- Cross-entity invariants are unit-gated: comment counts equal comment
  lists; designer follower counts mirror the follow graph (and update
  live on follow/unfollow); order snapshots are measured before their
  order exists; the explore premium band (> ₦100k) returns the seeded
  bridal gown.
- Captions describe their actual CC photos (the aso-oke/agbada/orange
  narratives were recaptioned to little senator / ceremonial robe set /
  resort one-piece to match the licensed pool); verified escrow figures
  (₦45,000 / ₦62,000) are unchanged.
- Feed comments open the in-app post modal — the public /p permalink is
  reserved for share targets (MI-9), never in-app navigation.
- `Select` passes `value ?? ""` to stay Radix-controlled for its whole
  life; overlays opened from other flows inherit the same rule.
- Marketing nav below md **[Revised 2026-07-19]**: the bar keeps the Try
  Cloud CTA beside the hamburger; the panel carries the 4 links +
  ThemeToggle + Sign in.
- Brand copy: "open-source" is hyphenated in prose; the community
  attribution reads "An open-source product by CueLABS™".

**Demo-completeness as-built notes (2026-07-19):** the P1 completeness
pass **[Directive]** — the review-fix set from the realism pass plus the
approved gap implementations:

- The post-detail modal (feed, explore, profile grids) opens on the
  Sheet's `wide` size axis — a real desktop width (896px,
  viewport-clamped), not a max-width fighting the base `md:w-*` utility —
  and the owning list re-syncs that post from the server on modal close
  (`useFeed.syncPost`), so cards never show stale like/save/comment state
  after in-modal interactions.
- Explore carries the full pages.md B2 chip set: style tags, price bands,
  turnaround time (≤ 1 week / ≤ 2 weeks / ≤ 1 month →
  `max_turnaround_days`), and "Near me" — proximity RANKING by designer
  `profile_location` vs the caller's (api.md §5 param extension; city >
  state > country, recency within tiers, locationless designers sort
  last, no hard gate). The seed carries one non-Lagos designer
  (`eniola.stitches`, Abuja, newest post) so the ranking is visible from
  boot; unit + e2e gate both chips.
- MI-6 feed infinite scroll is live: `/feed` pages through the api.md §4
  cursor contract at page size 4, prefetches when the viewer is 3 cards
  from the end (an IntersectionObserver over the last three cards),
  renders skeleton ×2 while the page is in flight, and lands the
  caught-up divider on cursor exhaustion.
- F2-9 session exports: the vault history sheet exports any session as
  CSV or PDF per row through `POST /sessions/{id}/exports` (the mock
  returns inline data URLs — a real minimal PDF for `pdf` — where the
  backend will return signed URLs); e2e asserts real browser downloads.
- Seed coherence: #APR-1058 ("Little senator") is a gift order freezing
  child-scale manual measurements entered at request time; #APR-1042's
  note asks for a skirt-appropriate alteration.
- The dashboard rail's two states are e2e-pinned
  (`e2e/nav-rail-states.spec.ts`): expansion is viewport-driven
  (collapsed 72px below 1264, expanded 244px at ≥1264; no user toggle,
  no persisted state), so an expanded rail can never squeeze the mobile
  content column; every dashboard route reflows cleanly at 1264/1440
  with content contained in the column.
- F0-8 Scalar embed at `/docs/api` **[Ratified 2026-07-20]**: the public
  API reference is the `@scalar/api-reference-react` embed
  (`ScalarApiReference` view) under the marketing nav with a minimal
  legal strip. It renders `docs/api/openapi.yaml` — the single spec
  source — served by the `/docs/api/openapi.yaml` route handler from a
  build-time string asset (`npm run generate:openapi`, wired as
  `predev`/`prebuild`/`pretypecheck`; output gitignored under
  `src/generated/`). Theme: the embed is forced to the RESOLVED theme
  via Scalar's `forceDarkModeState` (a creation-time override — the view
  mounts after hydration and remounts on theme change, since
  `updateConfiguration` never re-applies it); Scalar's own toggle is
  hidden and its remote default fonts are disabled (self-host ethos).
  Scalar's developer toolbar is pinned off (`showDeveloperTools:
  "never"` — the `"localhost"` default surfaced author chrome on the
  public reference in local/TEST_MODE runs).
  Header construction: the sticky marketing nav (h-16) and Scalar's
  sticky layout coexist via `--scalar-custom-header-height: 64px` on the
  embed wrapper (offsets Scalar's sticky sidebar/mobile bar below the
  nav and shrinks its viewport math — one coherent page scroll) plus
  `isolate` so no Scalar z-index paints over the nav. The footer Docs
  column's "API reference" links `/docs/api`; `e2e/docs-api.spec.ts`
  pins route 200, a rendered operation from the spec, the served
  document, the footer handoff, the header/scroll sanity and the
  embed-theme sync.

**Design-convergence as-built notes (2026-07-20):** the code-side fixes
from the Figma ↔ code divergence audit (seed-side details live in §6):

- Thread bubbles carry per-bubble timestamps (B3 frame): bare `HH:mm` for
  same-day messages, `MMM d, HH:mm` (the OrderTimelineRow idiom) when
  older, side-aligned under the bubble; delivered messages only — never
  sending or typing bubbles.
- Measurement values render **one decimal everywhere** ("92.0 cm", the
  frame's "58.0 cm" idiom) via `formatCm` — MeasurementCard, SessionRow,
  snapshot chips and the request stepper share the single formatter, so
  tnum columns stay aligned.
- Profile avatars render PLAIN — the measurement-freshness ring is a
  vault-header affordance (MI-11 **[Decided 2026-07-20]**, design.md §2);
  own profiles (regular-user and designer-self branches) carry no ring
  and fetch no vault, while other designers keep the B6 gradient story
  ring. The fresh/aging/stale → gradient/amber/gray mapping is one helper
  (`freshnessRing` on the Avatar atom) shared by the vault header and the
  feed freshness card.
- ModerationQueueRow anatomy matches the B7a canvas: headline carries the
  content author when known ("Reported post by @amara.designs"),
  reporters are @-prefixed, and actioned rows render the audit line
  ("Actioned · hide_comment by @mod.sarah · Jul 15, 09:12" — the
  effective action; `hide_post` on a comment subject reads
  `hide_comment`). Acting morphs the row in place; dismissing removes it;
  the queue banner links "Learn more" to the trust & safety doc.
- `UserRow` call sites (suggestions, explore designer search, follower
  sheets) pass `avatar_url` through — the row always supported it.

Screen-state parity **[Directive 2026-07-18, carried from design.md §8.1]**:
every data-driven screen ships default, empty, and loading states — the
three-frame rule applies to the implementation exactly as it does to the
Figma templates, and the QA loop checks all three.

**Floating-layer + band cross-check as-built notes (2026-07-20):** the
three-class cross-check (date-popover anatomy/overflow · modal-embedded
select clipping · two-column band balance) verified every instance
against its Figma master and fixed the hits:

- `DatePickerPopover` now carries the master anatomy (87:1035): 16px
  panel padding (was 12), 8px row gaps (was 2), Sunday-first
  `S M T W T F S` header (was Monday-first) at 12 semibold, 36×32 pill
  day cells at 13px (was 32×32 at 14), blank outside-month cells (was
  grayed adjacent-month days), a 1px border-token ring on today, and
  disabled days at `text-2/50` — today stays `text-2` at full opacity
  when the min-date rule disables it. Bottom-edge behavior verified at
  1440×900 and 1440×700: Radix flips the panel above the trigger when
  the space below runs out, never past the viewport and never adding
  document scroll height (locked in `dashboard.spec.ts`, serial fixture
  on `post-chromat-look`).
- Selects inside sheets (decline/dispute/report/stepper-address) came
  back clean — the W3 portal-at-z-40 + `max-h-72` pattern holds at both
  heights; now locked (`dashboard.spec.ts` decline,
  `floating-layers.spec.ts` report).
- B1 feed band matches the 176:72 frame exactly: 630px feed column +
  48px gutter + 320px meta rail (`max-w-[1030px]`/`gap-12`; the old
  `max-w-5xl`/`gap-16` squeezed the feed to 608 and stretched the gutter
  to 64).
- The order-detail thread panel fills the band beside the order content
  on `lg` (capped at 70vh) with the composer pinned to its bottom edge,
  per 179:536 — a short thread used to hug and leave ~576px of dead band
  under the card. Both bands locked in `band-balance.spec.ts` (±2px).

**Self-host tabbed snippet as-built (2026-07-20, PR #118).** The A7c
compose one-liner is now the user-approved Docker Compose | Helm tab pair
(Figma proposal 415:2), built as `CodeSnippetTabs` in the §8.2b marketing
kit beside `CodeSnippetBlock` (whose copy-pill grammar — Copy → ✓ Copied
morph — it reuses). Mirrored two-line commands: `git clone
https://github.com/cuesoftinc/apparule` shared; `cd apparule && docker
compose up --build -d` (the repo's `make up`) vs `cd apparule && helm
install apparule deploy/helm` (the real chart path). Copy targets the
ACTIVE tab's full block; the rendered `$ ` prompts are decorative
(select-none) and stay out of the payload. Tab grammar per the frame:
Micro/12 Semi Bold labels on the dark block, active = 2px `link`
underline, inactive at 60%; tablist semantics with roving tabindex +
Arrow/Home/End. Both tabs are two lines, so switching never shifts layout
(apparule carries no extra caption — the "what ships" lines stay). Unit:
`CodeSnippetTabs.test.tsx` (tab state, per-tab copy payload, roving
focus, copied-morph reset); e2e: `home.spec.ts` pins helm-tab copy → the
clipboard payload plus the 1440/390 container fit.

**Sheet focus-restore as-built (2026-07-21 a11y audit).** `Sheet` owns the
overlay focus contract: it is announced `aria-modal`, and because sheets are
controlled dialogs with no `RadixDialog.Trigger`, the component captures the
opener element on open (`onOpenAutoFocus`, before Radix moves focus into the
panel) and returns focus to it on close — Radix's default would target a
null trigger and drop focus on `<body>`. Callers never manage focus restore
themselves. Locked by `Sheet.test.tsx` (unit) and `e2e/focus-restore.spec.ts`
(open → Tab inside → Escape → trigger refocused), the org P4 probe shape.

## 3. Token mapping — design.md §2 → `web/src/design/tokens.css`

One custom property per Figma variable in the `apparule/tokens` collection
(design.md §7); light values on `:root`, dark on `[data-theme="dark"]`
(the tokens.css `prefers-color-scheme` block remains as the no-JS
fallback only).

**Theme contract as-built (2026-07-20, ratified — identical across
apparule, expendit and upstat).** The preference is tri-state
light | dark | system: `ThemeProvider` persists it at `apparule.theme`
("light"/"dark"/"system" all stored explicitly; KEY ABSENT = light,
apparule's design default — the cross-product storage convention;
"system" is never modeled as key-absent), and `data-theme` on `<html>`
always carries the RESOLVED theme — system resolves via `prefers-color-scheme`
and tracks it live (a matchMedia listener updates `data-theme` on an OS
flip, no reload). The pre-paint init script applies the resolved theme
(no FOUC in any mode). `ThemeToggle` (marketing nav + NavRail rail item)
cycles light → dark → system with distinct icons (sun / moon / monitor);
its aria-label announces the active mode. Settings → Appearance keeps
the three-way System/Light/Dark select over the same `setPreference`.
The Scalar embed follows `resolvedTheme` (F0-8 note, §2). Unit tests pin
the storage convention, live system tracking and cycle order; e2e pins
the cycle, an emulated OS flip in system mode and reload persistence.

| Group | Token names |
| --- | --- |
| Color | `--bg` · `--bg-elev` · `--border` · `--text` · `--text-2` · `--accent-start` · `--accent-end` (the two gradient stops — same two-variable shape as Figma, design.md §2 **[Decided 2026-07-17]**) · `--on-accent` · `--link` · `--like` · `--success` · `--warn` · `--error` |
| Spacing | `--space-4` `--space-8` `--space-12` `--space-16` `--space-24` `--space-32` `--space-48` `--space-64` — the 4px-grid scale, no off-scale values |
| Radii | `--radius-card: 8px` · `--radius-full: 9999px` (avatars/pills) |
| Motion | `--duration-fast: 120ms` · `--duration-base: 200ms` · `--duration-slow: 300ms` · `--duration-entrance: 250ms` · `--ease-standard: cubic-bezier(0.2, 0, 0, 1)` · `--ease-exit: cubic-bezier(0.4, 0, 1, 1)` |
| Z layers | `--z-base: 0` · `--z-sticky: 10` · `--z-dropdown: 20` · `--z-overlay: 30` · `--z-sheet: 40` · `--z-toast: 50` |

Notes: Apparule has no chart series palette (the ecosystem row applies only
where a product has one). The Afrocentric pattern (design.md §2) is an
asset at fixed opacities, not a token. The `accent` gradient is composed in
CSS from `--accent-start`/`--accent-end`; `--on-accent` replaces raw white
on gradient/destructive fills (exception: on-media capture UI, by design).
Tabular numerals (`font-variant-numeric: tabular-nums`) apply wherever the
design.md §7 `tnum` note applies — measurement values and money.

**Type as-built (2026-07-20, font-weight audit vs the Figma Home frame).**
Inter loads via `next/font` in `layout.tsx` (variable font — the ramp's
400/600/700 are real faces, no synthetic bolding) and reaches components as
`--ap-font-sans` = `var(--font-inter)` + the system stack as fallback; the
computed family therefore matches the Figma type styles on every platform.
The Tailwind ramp utilities pin the styles' tracking — `text-title-lg`
−0.25px, `text-display` −0.5px, all smaller sizes 0 — so components never
hand-set `tracking-*` for ramp roles. Font smoothing stays `antialiased` on
`<html>` (expendit sets the same pair in CSS; grayscale AA is also how the
canvas rasterizes, keeping weights visually comparable). The home e2e
journey carries the regression lock: per-role computed
family/weight/size/line-height/letter-spacing plus a `document.fonts.check`
that the three ramp weights loaded as real Inter faces.

## 4. Route map — pages.md Part A/B → app routes

pages.md writes Part B routes with an `/app` shorthand prefix "relative to"
the canonical `apparule.cuesoft.io/dashboard` base **[Decided]**. This map
resolves that notation **[Proposed]**: `/app/X` ⇒ `/dashboard/X`, with the
feed at the base itself.

| pages.md | Route | Screen |
| --- | --- | --- |
| Part A (A1–A10 + A4b/A7b/A7c/A9b/A9c) | `/` | Public home page |
| B2 permalink note | `/p/{post_id}` | Public post detail (MI-9 share target; request CTA for signed-in users) |
| flows/auth.md §5 | `/signin` | Single auth screen — GoogleAuthButton + legal links **[Decided 2026-07-18, route canon]** |
| F0-8 / APP-004 | `/docs/api` | Public API reference — Scalar embed rendering `docs/api/openapi.yaml` (served at `/docs/api/openapi.yaml`); marketing nav chrome, minimal legal strip **[Ratified 2026-07-20]** |
| B1 | `/dashboard` | Feed (story rail, PostCard column, freshness + suggestions) |
| B2 | `/dashboard/explore` | Discover (masonry, filters, search-results state) |
| B3 | `/dashboard/orders` · `/dashboard/orders/{id}` | Requests & orders — tabs, detail (snapshot, thread, timeline, payment box, decline sheet, dispute flow) |
| B4 | `/dashboard/vault` | Measurement vault |
| B5 | `/dashboard/create` | Post an outfit (designer) / creator upsell |
| B6 | `/dashboard/{username}` | Profiles (designer / regular; followers/following sheets) |
| B7 | `/dashboard/settings` + sub-screens `/dashboard/settings/notifications` · `/dashboard/settings/privacy` · `/dashboard/settings/account` | Settings + the three 2026-07-18 sub-screens |
| B7a | `/dashboard/admin/moderation` | Moderation queue (staff only) |
| B8 | `/dashboard/designer/onboarding` | Designer onboarding & KYC |
| B9 | `/dashboard/earnings` | Earnings & payouts (designer) |

`/dashboard/{username}` is a dynamic segment; static siblings (explore,
orders, …) win route precedence by App Router rules, and those segment
names are reserved usernames at claim time (api.md `/me` — `409
name_taken`). Part C (mobile) has no web routes — it is the Flutter phase
(§8).

## 5. TEST_MODE contract

`NEXT_PUBLIC_TEST_MODE=1` (build-time inlined, like all `NEXT_PUBLIC_*` —
[setup.md](setup.md)) switches exactly two seams; nothing else may branch
on it:

1. **Auth**: the `AuthProvider` resolves to `TestModeAuthProvider` —
   GoogleAuthButton navigates straight to `/dashboard` as the seeded test
   user (§6), no Firebase SDK loaded, no popup. The interface is identical
   to the future `FirebaseAuthProvider` (X-1 Google-only, bearer-token
   shape preserved), so backend integration swaps the provider, not the
   views.
2. **API client**: the models layer's base URL targets the in-app mock
   server — `/api/mock/v1/*` mirrors the `/api/v1/*` surface path-for-path,
   so repositories are identical in both modes except for the base URL.

Unset (or `0`) → real `FirebaseAuthProvider` + `NEXT_PUBLIC_BASE_URL`
(api/common). TEST_MODE is how Playwright runs in CI and how the app is
developed before the backend lands.

## 6. Mock server & seed narrative

Route handlers under `web/src/app/api/mock/*` implement the api.md surface
the web consumes — target-surface paths (§2) plus the social-commerce
expansion (§5) — with the engineering.md §1 error envelope, its snake_case
code catalog, cursor pagination (api.md §4), and the documented enum
taxonomies (order states, QC codes, report reasons, notification kinds).
Backed by one seeded in-memory store (module singleton, dev-persistent)
with full CRUD; contract types shared with `src/models/`.

| Group | Mocked endpoints (under `/api/mock/v1`) |
| --- | --- |
| Auth & consent | `GET/PATCH /me` · `GET/POST /consent` |
| Vault (self-customer alias, data-model.md §6.1) | `GET/POST /me/sessions` · `GET /sessions/{id}` · `PATCH /sessions/{id}/measurements` · `POST /sessions/{id}/exports` |
| Posts | `POST /posts` · `GET /posts/{id}` · `GET /feed` · `GET /explore?q&tags&price_band&max_turnaround_days&near_me` · `DELETE /posts/{id}` |
| Social graph | `POST/DELETE /follows/{designer}` · `POST/DELETE /posts/{id}/like` · `/save` · `GET/POST /posts/{id}/comments` |
| Trust & safety | `POST /reports` · `POST/DELETE /blocks/{account}` · `GET /moderation/queue` · `POST /moderation/reports/{id}/action` |
| Requests | `POST /posts/{id}/requests` · `GET /requests?role=` · `GET /requests/{id}` · `/quote` · `/decline` · `/status` · `/messages` |
| Payments | `POST /requests/{id}/pay` (resolves synchronously to `held` — the mock stands in for the provider round-trip + webhook) · `/confirm-delivery` · `/dispute` |
| Designer | `POST /designer-profile` (incl. scripted Paystack account-resolution states: resolving → resolved / mismatch, pages.md B8) · `GET /designer/earnings` · `POST /designer/payout-account` |
| Notifications | `GET /notifications` · `POST /notifications/read` |
| Capture (webcam path, B4) | `POST /me/sessions` with multipart image — returns seeded measurement results incl. per-measurement `confidence` and `qc` verdicts (api.md §2 v2 schema); QC-failure codes reproducible via designated fixture images |

**Seed narrative — the docs-coherent Figma dataset.** The store seeds the
same mock content the Figma screens render, so a TEST_MODE boot looks like
the designs:

- A cast of Nigerian designer personas with published posts using the
  CC-sourced outfit photography (design.md §8.3 — same pool as the Figma
  Assets page), captions, style tags, and NGN pricing spread across the
  explore price bands (api.md §5: budget <25k, mid 25–100k, premium >100k).
  Suggested designers (the B1 rail) carry real photo avatars — each fronts
  their OWN published photography from the licensed pool, so the booted
  rail matches the canvas without new assets or fabricated identities.
- The signed-in test user: non-designer, vault populated with scan +
  manual sessions whose `measured_at` spread exercises all three freshness
  ring states (fresh/aging/stale, MI-11), follows several designers (story
  rail + feed content, plus a caught-up divider within reach).
- Orders covering **all ten states** (requested → … → cancelled), at least
  one per state and per role view, so every StatusPill, OrderTimelineRow,
  and PaymentBox variant renders from seed — including an escrow-held
  payment with the itemized 10% fee line and a dispute-frozen order.
  Timestamps follow the **plausible-cadence rule**: each order's events
  spread across real-looking hours (strictly ordered, never a same-minute
  cluster; the order and its frozen snapshot anchor to the requested
  event) and thread messages sit minutes-to-hours around the events they
  narrate — unit-gated in `store.test.ts`.
- Notifications of every kind (like / follow / comment / quote /
  status-change / payout), part unread; a designer persona with
  EarningsSummary balances and TransactionRow history for B9.
- A moderation queue in the B7a canvas shape: two open reports (a spam
  comment and a reported post with thumb + author) plus one ACTIONED
  audit-trail exemplar by the seeded staff moderator (`mod.sarah`).
  Reported comments exist as previews only, so post comment_counts stay
  honest. The mock's REPORT carries audit fields — `action`,
  `actioned_by {id, username}`, `actioned_at`, subject author — ahead of
  the data-model.md §6.2 sketch (deviation noted, same as the profile
  reads); the queue lists open rows first with actioned rows trailing as
  the audit trail, and dismissals drop out.
- Measurement snapshots frozen per request (vault edits after seed never
  mutate them — the data-model.md §5 rule holds in the mock too).

**Demo imagery pipeline.** The CC pool lives in `web/public/demo/`
(originals byte-stable — they are the attributed derivatives manifested in
`ATTRIBUTIONS.md`) alongside pre-generated responsive WebP variants
(`<base>.w128/.w384/.w640/.w960.webp`, from
`web/scripts/generate-demo-image-variants.mjs`; rerun it when the pool
changes). All demo imagery renders through `next/image` with a custom
loader (`src/lib/demo-image-loader.ts`) that maps srcset widths onto those
variant buckets — the deploy target (Firebase App Hosting adapter)
disables Next's runtime optimizer, so `/_next/image` never exists in
production and serve-time optimization can't be assumed. Config
`deviceSizes`/`imageSizes` mirror the buckets 1:1. Priority discipline:
exactly one `priority` image per route — on home it's the hero phone
mock's first feed photo (the mobile LCP element); everything else stays
lazy. Non-path srcs (`blob:` capture previews) stay raw `<img>` and pass
through the loader untouched. Locked by the home e2e perf canon
(`e2e/home.spec.ts`).

## 7. Test strategy

| Layer | Tooling | Scope |
| --- | --- | --- |
| Unit | Vitest + Testing Library | every `components/ui/*` module (variant axes, states, both themes, reduced-motion fallbacks); model/repository parsing incl. error-envelope handling; controller hooks |
| Integration | Vitest | mock handlers (envelope, pagination, enum taxonomies, state-machine legality of `/status` transitions); controller ↔ mock-server flows (optimistic MI-18 rollback on scripted failures) |
| E2E | Playwright, TEST_MODE against the mock server | the design.md §8.4 prototype journeys, web-applicable set: **Marketing site** (Part A scroll + CTA handoff into the app), **Feed** (B1: like/save/follow → post detail → request stepper MI-10 → pay → escrow-held), plus the named state starts — **decline**, **dispute/moderation**, **creator-upsell** (B5 as non-creator), **designer onboarding/KYC → payout** (B8 → B9) |
| CI | build-and-test workflow | lint + typecheck + Vitest + Playwright on every PR; X-6: merge-to-main never deploys |

The §8.4 rule that empty/loading/QA frames stay out of the prototype maps
here too: Playwright walks real user paths; empty/loading states are
asserted at unit/integration level (screen-state parity, §2).

## 8. Legacy quarantine

Live paths carry zero dead code. `web/src/legacy/` plus the boundary gates
(the eslint `no-restricted-imports` rule scoped to `src/legacy/**` and
`scripts/check-boundaries.mjs`, wired into `npm run lint`) are the standing
mechanism for future replacements per the §1 policy (quarantine → replace →
QA → dedicated retirement PR) — the directory is currently empty. The
**mobile Flutter app is a later phase**: `mobile/` (existing auth + capture
screens, design.md §6) gets its own implementation standard — including its
own application of the quarantine policy — when that phase opens.

## 9. Acceptance

- [ ] `tokens.css` matches design.md §2 / the `apparule/tokens` collection
      exactly, both themes; no raw hex in components (CI grep-gated)
- [ ] W0–W3 each closed by a Figma QA loop before merge; deviations landed
      in docs + the org SKILL.md
- [ ] TEST_MODE boots to `/dashboard` with the §6 seed rendering the
      Figma-coherent narrative; no Firebase loaded
- [ ] Every mocked endpoint speaks the engineering.md §1 envelope with
      catalog codes; contract types shared with models
- [ ] Views contain no fetch calls (MVC boundary enforced by review +
      lint rule)
- [ ] Playwright §8.4 journeys green in CI; merge-to-main never deploys
      (X-6)

## 10. SEO plumbing (as-built, 2026-07-21)

Fleet-uniform discoverability layer (same construction in all three
products; per-product values only):

- **`src/app/sitemap.ts`** — public marketing routes only: `/` and
  `/docs/api`. No `/dashboard/*`, no `/signin`; `/p/{post_id}` permalinks
  are runtime content, not build-time sitemap entries.
- **`src/app/robots.ts`** — allow `/`, disallow `/dashboard` and `/api`;
  references `https://apparule.cuesoft.io/sitemap.xml`.
- **Canonical** — root layout sets
  `metadataBase = https://apparule.cuesoft.io` and
  `alternates.canonical = "./"`, so every route emits its own path as the
  canonical URL.
- **og/twitter card** — `src/app/opengraph-image.png` (1200×630, App Router
  file convention): gradient wordmark + tagline on the light token canvas;
  `twitter:card = summary_large_image`.
- **Icons** — `src/app/favicon.ico` (16/32/48/256 PNG-in-ICO) and
  `src/app/apple-icon.png` (180×180): white "A" on the accent gradient
  tile. Replaces the stock create-next-app icon the repo had shipped since
  scaffold (byte-identical with upstat's — neither product's mark).
- **Provenance** — all three binaries are generated from the design tokens
  by `web/scripts/generate-brand-assets.mjs` (byte-identical across repos,
  config keyed by package name; Inter via `INTER_WOFF2` or the official
  distribution).
- **Lock** — `web/e2e/seo.spec.ts` (byte-identical across repos) asserts
  sitemap 200 + exact route set, robots policy + sitemap reference,
  canonical on `/`, og:image resolves 200 at 1200×630, twitter card, and
  the served favicon's sha256 equals apparule's mark while differing from
  both siblings'.
