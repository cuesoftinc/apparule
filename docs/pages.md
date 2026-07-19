# Apparule — Pages, Screens & Features

> Every surface of the product, to component level, referencing the design
> system and microinteractions in [design.md](design.md) (`MI-n`). Three
> parts: **A** public home page, **B** web dashboard, **C** mobile app.
> The social model (posts, likes, requests, payments) is the 2026-07-16
> scope expansion **[Directive]**; entities in [data-model.md](data-model.md) §5.

## Part A — Public home page (apparule.cuesoft.io)

Standard CueLABS open-source product site (shared pattern across the three
products **[Directive]**): present the product → developers can set it up →
community links → preview → dual CTA **Try Cloud** / **Self Host**.

| # | Section | Content & components | Interactions |
| --- | --- | --- | --- |
| A1 | Nav bar | logo · text links Features · For designers · Docs (GitBook) · GitHub · theme toggle · **Sign in** (gradient CTA, `/signin`) — the parity-canon inventory (design.md §8.2b); the runtime star-count badge is A7b's alone | sticky, blurs on scroll; `github_click` fires on the GitHub link |
| A2 | Hero | H1 "Precision measurement meets social fashion" (copy pass pending); subcopy; dual CTA **Try Cloud** / **Self Host**; hero visual: phone frame auto-playing a silent feed→capture→request loop | CTA hover lifts 2px; visual loop pauses on hover/reduced-motion |
| A3 | Problem strip | 3 stat cards (manual-measurement error, fragmented records, lost designer reach) | cards fade-up on scroll-into-view (once) |
| A4 | Product walkthrough | 4-step horizontal scroll-jacked panel (Capture → Vault → Discover → Commission), each step = **real screen thumbnail** (exported from the Stage-4 Figma frames, not illustrative art **[Directive 2026-07-18]**) + 2 lines | step dots + keyboard arrows; scroll-jack disabled on mobile (vertical stack) |
| A4b | Feature deep-dives **[Directive 2026-07-18]** | benefit-led split panels (alternating media/text) going deeper than A4's steps: Capture ("a tape measure that lives in your camera"), Vault (history, freshness, consent), Discover & Commission (measurements attached, escrow-protected payment) — each = benefit headline · 2–3 line body · real screen thumbnail · quiet link (docs deep-dive) | panels fade-up on scroll-into-view (once, same rule as A3) |
| A5 | SMPL/AI section (APP-003) | short explainer "AI-assisted body modeling", looping landmark-constellation animation (same asset as MI-12), link → GitBook deep-dive | |
| A6 | For designers | split panel: "Post outfits, get commissioned, get paid" + earnings screenshot | |
| A7 | Open source section | `docker compose up` snippet with copy button · architecture mini-diagram · GitHub + CONTRIBUTING links | copy button ✓ morph |
| A7b | For developers — Contribute **[Directive 2026-07-18]** | stack line (Flutter · Go/Gin `api/common` · Python/FastAPI `api/measure`, architecture.md) · "interesting problems" list (on-device capture QC, escrow ledger, single-image SMPL fitting) · links: good-first-issues filter, CONTRIBUTING.md, Discord · GitHub star badge (the live count is populated at runtime; static designs render the badge with no number per the accuracy standard, design.md §8.2b — the only star-count badge on the page) | link cards lift 2px on hover; `github_click` fires here too; star count animates count-up once |
| A7c | Self-host **[Directive 2026-07-18]** | data-ownership pitch (your measurements on your own metal — nothing leaves your server) · `docker compose up -d` one-liner (same snippet asset as A7) · "what ships" list (`api-common` · `api-measure` · `web`, per docker-compose.yml) · link → docs quickstart (GitBook) | copy button ✓ morph (shared with A7); `self_host_click` fires here too |
| A8 | Community | Discord card (member count), roadmap link, CueLABS note | |
| A9 | Cloud vs Self-host table (PRD §3) | feature comparison; Cloud column ends in Try Cloud CTA, OSS column in Self Host (→ docs quickstart) | |
| A9b | FAQ **[Directive 2026-07-18]** | 4–5 product Q&As as accordion rows: "How accurate are the measurements?" · "Who can see my measurements?" (never public; snapshot only inside a request) · "How do designers get paid?" (escrow → payout, order-lifecycle.md) · "Can I self-host?" (→ A7c) · "Is it really open source?" (license) | one panel open at a time; rows deep-linkable (`#faq-n`) |
| A9c | Final CTA band **[Directive 2026-07-18]** | full-width gradient band: one-line close + dual CTA **Try Cloud** / **Self Host** (repeats the A2 pair — last conversion point before the footer) | CTA hover lifts 2px (as A2); `try_cloud_click` / `self_host_click` |
| A10 | Footer | brand block (wordmark + tagline) · Product / Docs / Community / Legal link columns — privacy (APP-005), terms and status live in the Legal column (`privacy/terms/status.cuesoft.io`) · legal bar `© Cuesoft Inc. 2026. Apparule. CueLABS™ Division. MIT License.` with security-policy link (SECURITY.md) · English language selector — the parity-canon inventory (design.md §8.2b) | |

Analytics events (→ Upstat, D2): `page_view`, `demo_start` (A4 engage),
`github_click` (A1/A7), `try_cloud_click`, `self_host_click`. **[PRD + Directive]**

Docs: hosted on **GitBook** (Git-synced from this `docs/` folder) **[Directive]**;
API reference via **Scalar** rendering the OpenAPI specs (api.md) embedded at
`/docs/api`. **[Proposed]**

## Part B — Web dashboard (`apparule.cuesoft.io/dashboard` — canonical [Decided]; "B" routes below are relative to it)

Desktop adaptation of the mobile IA (design.md §2 layout). Left rail: Home,
Explore, Create, Orders, Vault, Profile, Settings; bottom of rail: theme
toggle, support (`clients.cuesoft.io`).

### B1 `/app` — Feed
- Story rail (fresh outfits from followed designers, MI-8) above feed.
- `PostCard` column (630px): MI-1/2/3/4/9 all active; "Request this outfit"
  CTA on designer posts → request stepper (MI-10) in modal.
- Right column: own measurement-freshness card (MI-11) + suggested designers
  (Follow, MI-7).
- States: skeleton (MI-19) · empty ("Follow designers to fill your feed" +
  explore CTA) · caught-up divider (MI-6).

### B2 `/app/explore` — Discover
- Search bar (designers, styles, tags) with recent-searches dropdown.
- Masonry grid of outfit posts (1:1 crops); hover: like/comment counts
  overlay fade-in 120ms; click → post modal (IG desktop pattern: media left,
  detail right).
- Filter chips: style tags, price band, turnaround time, "near me" **[Proposed]**
  — proximity ranking by designer `profile_location` (data-model.md §2,
  X-10 tier 1); designers without a location simply don't rank in proximity
  results (no hard gate).
- Post permalinks: every post has a public web route `/p/{post_id}` (share
  target for MI-9; renders post detail, request CTA for signed-in users).
- Search-results state **[Directive 2026-07-18]**: submitting a query swaps
  the masonry for sectioned results — Designers (UserRow list, Follow MI-7)
  above Posts (grid) — with per-section empty copy ("No designers match…").

### B3 `/app/orders` — Requests & orders (both roles)
- Tabs: **As customer** / **As designer** (designer tab only when creator
  profile enabled).
- `RequestCard` list; status pills (MI-14): `requested → quoted → paid →
  in_progress → shipped → delivered` (+ `refunded`, `declined`, `disputed`,
  `cancelled`).
- Click → order detail: outfit summary · **measurement snapshot** (the exact
  values sent, immutable) · thread (MI-17) · timeline (MI-14) · payment box
  (MI-15: quote → pay → escrow-held → released on delivery confirm)
  **[Proposed payment model — ratify]**.
- Designer actions per state: quote (price + due date) / decline with reason /
  mark in-progress / mark shipped (tracking optional) ; customer: pay, confirm
  delivery (releases payout), open dispute.
- Decline-with-reason sheet (designer) **[Directive 2026-07-18]**: reason enum
  (Select, design.md §8.2b) + optional note — reason required per
  flows/designer.md §2; sets the `declined` pill + notifies the customer.
- Order dispute flow (either party, order-lifecycle.md §1) **[Directive
  2026-07-18]**: open from paid/in_progress/shipped → reason picker + note →
  order enters `disputed` (payout frozen, PaymentBox dispute-frozen state
  MI-15) → staff-resolved thread (resolve = support/admin only).

### B4 `/app/vault` — Measurement vault
- Header: freshness ring avatar (MI-11) + "Retake" CTA → capture options
  (webcam upload / manual entry MI-13; phone hand-off QR was CUT from scope — mobile capture covers it **[Decided]**).
- `MeasurementCard` grid (shoulder, hip, +SMPL girths when available) with
  history sparklines; tap → history sheet (sessions list, method chips,
  delete session).
- Consent + retention notice inline (data-model.md §4); "Download my data" /
  "Delete all" links (rights parity with expendit **[Proposed]**).

### B5 `/app/create` — Post an outfit (designer)
- Dropzone (≤10 media, reorder by drag; MI-4 preview) → details form
  (caption, style tags, base price or "quote on request", turnaround days,
  fabric notes) → publish. Media limits **[Decided]**: images only in v1 (video
  is a later decision), ≤10 items, ≤10 MB each, JPEG/PNG/WebP, client-resized
  to ≤2048px long edge; alt text required (default "Outfit by {designer}").
- Non-creator users see the creator-profile upsell here ("Become a designer").

### B6 `/app/{username}` — Profiles
- Designer: avatar + story ring, follower/following/posts counts, Follow
  (MI-7), Request CTA, bio, grid/saved tabs; earnings tab visible only to
  self (payout balance, payout account setup, transaction list) **[Proposed]**.
- Regular user: private vault indicator (measurements NEVER public), saved
  looks tab, order history link. Privacy default: vault visible to no one;
  a measurement snapshot is shared **only** inside a request (APP-005 story).
- Followers/following lists **[Directive 2026-07-18]**: tapping either count
  opens a UserRow list sheet (Follow/Following morph MI-7; tabs switch the
  two lists).

### B7a `/dashboard/admin/moderation` (staff only)
- Moderation queue (A-6): open reports with subject preview, reporter
  context, actions hide_post / suspend_account / dismiss (api.md §5 T&S);
  audit trail via `REPORT.actioned_by`.

### B7 `/app/settings`
- Account (Google sign-in via Firebase per X-1; `account.cuesoft.io` facade later), creator profile toggle,
  payout account (designer), **profile location** (city/state/country,
  optional — explainer: "used to recommend nearby designers"; X-10 tier 1,
  data-model.md §2), notifications, privacy & data (export/delete,
  consent history), language, theme.
- Sub-screens **[Directive 2026-07-18]**: **Notifications** (per-event
  toggles: quotes, order status, social, payouts) · **Privacy & consent**
  (consent history, capture-data retention notice, data-model.md §4) ·
  **Account & data** (export / delete-all with confirm — the B4 rights links
  resolve here).

### B8 `/app/designer/onboarding` — Designer onboarding & KYC **[Directive 2026-07-18]**
- Intro screen (what you get: posts, commissions, payouts; flows/designer.md
  §1) → banking form: bank Select + account number with **Paystack
  resolution states** (resolving spinner → resolved account-name confirm /
  mismatch error, retry + support link after 3 fails) → done.
- KYC-lapse banner state (Banner warn, design.md §8.2b): posts stop accepting
  requests, payouts queue until re-verification — persistent until resolved.

### B9 `/app/earnings` — Earnings & payouts (designer) **[Directive 2026-07-18]**
- Expands the B6 self-only earnings tab into a full screen: EarningsSummary
  cards (released balance / pending escrow) + TransactionRow list (payouts,
  escrow-held, itemized 10% fee lines, provider refs); payout-account status
  chip → B8 to fix.

## Part C — Mobile app (Flutter) — primary surface

Bottom tab bar: **Home · Explore · ➕ · Orders · Profile** (design.md §3).
Existing screens (splash/welcome/auth/capture) remain the entry path.

| # | Screen | Spec |
| --- | --- | --- |
| C1 | Onboarding | Google-only sign-in (flows/auth.md §5 — one CTA screen; password/verification screens retired); first sign-in hands off to C1b |
| C1b | Post-signup interstitial | "Take your first measurement" (→C6) or "Explore outfits" (→C3) — skippable; split out of the C1 row 2026-07-18 (the QA loop built it as its own screen) |
| C2 | Home feed | = B1 minus right column; story rail on top; MI-1/2/3/4/5/6/16/18/20 all active |
| C3 | Explore | search + 3-col grid; long-press peek preview (scale 0.97 + dim, MI haptic light); pull-to-refresh MI-5; search-results state = B2 **[Directive 2026-07-18]** |
| C4 | Post detail | full-bleed carousel; action row; caption; comments sheet (swipe-up); Request CTA pinned bottom (safe-area) |
| C5 | Request stepper | MI-10 sheet: Step 1 pick measurement set (vault snapshot picker, freshness warnings); Step 2 notes + budget + delivery (pre-fills from most recent order — no saved address book in v1, data-model.md §6.3); Step 3 review → submit; success: confetti + "view order" |
| C6 | Capture | existing guide screens restyled: silhouette overlay + countdown (MI-12); processing constellation; results screen: measurement cards stagger-in, "Save to vault" primary, "Retake" quiet; manual-entry fallback (MI-13) |
| C7 | Vault | = B4 adapted; entry from Profile tab header ring |
| C8 | Orders | = B3 list + detail, incl. the dispute flow and designer decline sheet **[Directive 2026-07-18]**; push notifications drive re-entry (badge MI-16) |
| C9 | Profile | own: vault ring header, grid of liked/saved, settings gear; others: designer profile = B6 |
| C10 | Notifications sheet | activity list (likes, follows, quotes, status changes); grouped by day; swipe-to-clear |
| C11 | Comments sheet (full) **[Directive 2026-07-18]** | C4's swipe-up sheet expanded to full height: CommentRow list (reply indent, like hearts), composer pinned above keyboard, optimistic post MI-18 |
| C12 | Followers/following **[Directive 2026-07-18]** | = B6 lists; UserRow + Follow morph (MI-7), tabs Followers / Following |
| C13 | Designer onboarding & KYC **[Directive 2026-07-18]** | = B8: intro → banking form (Paystack resolution states: resolving / resolved-name confirm / mismatch error) → done; KYC-lapse banner state |
| C14 | Earnings & payouts **[Directive 2026-07-18]** | = B9: EarningsSummary + TransactionRow list; payout push notifications deep-link here |

Push notifications **[Proposed]**: quote received, payment confirmed, status
changes, delivery confirm reminder (customer), new request (designer).

## Feature register delta (extends prd.md §3)

| ID | Feature | Priority | Surfaces |
| --- | --- | --- | --- |
| SOC-001 | Designer posts (media, tags, price, turnaround) | Must | B5, C2–C4 |
| SOC-002 | Follow graph + home feed + explore | Must | B1/B2, C2/C3 |
| SOC-003 | Likes, saves, shares, comments | Must | feed/post surfaces |
| SOC-004 | Commission request with measurement snapshot | Must | B3, C5 |
| SOC-005 | Order lifecycle + thread messaging | Must | B3, C8 |
| SOC-006 | Payments: customer pay, escrow hold, designer payout, platform fee | Must | B3, B6 earnings **[payment provider + fee % to ratify]** |
| SOC-007 | Creator profiles (role toggle, earnings) | Must | B6, B7 |
| SOC-008 | Notifications (in-app + push) | Should | C10 |
| SOC-009 | Comments moderation, report/block | Should | trust & safety baseline for UGC **[Proposed — required before public launch]** |
| SOC-010 | Full DMs beyond order threads | Later | — |

Cross-refs: data model additions → data-model.md §5; API additions →
api.md §5; sequencing → roadmap.md (revised phases).
