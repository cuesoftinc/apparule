# Apparule — Web Implementation Standard

> How `web/` gets built: the **CueLABS Web Implementation Standard**
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
| **W3 Dashboards** | Part B routes (§4): B1–B9 + B7a · feature controllers · request stepper, payments UI, vault, moderation | QA vs the Stage-4 Figma frames + prototype flows; Playwright covers the §8.4 dashboard journeys (§7) |

**W2 as-built notes (2026-07-19, PR #87):**

- Hero phone mock is a live composed component loop (pauses on hover and on
  `prefers-reduced-motion`), not a static image or video asset.
- Walkthrough and feature-deep-dive thumbnails are composed mini-previews
  standing in for the real screens; the W3 raster swap replaces them.
- FAQ answers 2–5 are authored to the pages.md contract.
- The theme toggle lives in `HomeNav`, not a standalone control.
- Analytics events land on a TEST_MODE queue behind an `AnalyticsTransport`
  seam — the Upstat transport wires in at D2.
- The GitHub star badge renders neutral first, then resolves via a runtime
  fetch (no build-time count).
- Registry `ComparisonTable`, `CommunityCard`, and `WalkthroughStep` were
  rebuilt to the enriched Figma masters during the W2 QA loop.
- Section components live in `web/src/components/home/` (canon).

Screen-state parity **[Directive 2026-07-18, carried from design.md §8.1]**:
every data-driven screen ships default, empty, and loading states — the
three-frame rule applies to the implementation exactly as it does to the
Figma templates, and the QA loop checks all three.

## 3. Token mapping — design.md §2 → `web/src/design/tokens.css`

One custom property per Figma variable in the `apparule/tokens` collection
(design.md §7); light values on `:root`, dark on `[data-theme="dark"]`,
`prefers-color-scheme` honored with manual override (the NavRail theme
toggle sets `data-theme`).

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
| Posts | `POST /posts` · `GET /posts/{id}` · `GET /feed` · `GET /explore?q&tags&price_band` · `DELETE /posts/{id}` |
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
- The signed-in test user: non-designer, vault populated with scan +
  manual sessions whose `measured_at` spread exercises all three freshness
  ring states (fresh/aging/stale, MI-11), follows several designers (story
  rail + feed content, plus a caught-up divider within reach).
- Orders covering **all ten states** (requested → … → cancelled), at least
  one per state and per role view, so every StatusPill, OrderTimelineRow,
  and PaymentBox variant renders from seed — including an escrow-held
  payment with the itemized 10% fee line and a dispute-frozen order.
- Notifications of every kind (like / follow / comment / quote /
  status-change / payout), part unread; open moderation-queue reports; a
  designer persona with EarningsSummary balances and TransactionRow
  history for B9.
- Measurement snapshots frozen per request (vault edits after seed never
  mutate them — the data-model.md §5 rule holds in the mock too).

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

## 8. Legacy quarantine plan

`web/` is **greenfield** — the current tree is the template stub (a
placeholder home page + a thin API helper), not a legacy system; W0
replaces it in place and no `src/legacy/` quarantine is needed at the
start. The §1 policy still governs any future replacement inside `web/`
(quarantine → replace → QA → dedicated retirement PR). The **mobile Flutter
app is a later phase**: `mobile/` (existing auth + capture screens,
design.md §6) is untouched by W0–W3 and gets its own implementation
standard — including its own application of the quarantine policy — when
that phase opens.

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
