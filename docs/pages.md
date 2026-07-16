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
| A1 | Nav bar | logo · Product · Docs (GitBook) · Community · GitHub (star count badge) · Sign in · **Try Cloud** (gradient) | sticky, blurs on scroll; star count fetched client-side, animates count-up once |
| A2 | Hero | H1 "Precision measurement meets social fashion" (copy pass pending); subcopy; dual CTA **Try Cloud** / **Self Host**; hero visual: phone frame auto-playing a silent feed→capture→request loop | CTA hover lifts 2px; visual loop pauses on hover/reduced-motion |
| A3 | Problem strip | 3 stat cards (manual-measurement error, fragmented records, lost designer reach) | cards fade-up on scroll-into-view (once) |
| A4 | Product walkthrough | 4-step horizontal scroll-jacked panel (Capture → Vault → Discover → Commission), each step = screenshot + 2 lines | step dots + keyboard arrows; scroll-jack disabled on mobile (vertical stack) |
| A5 | SMPL/AI section (APP-003) | short explainer "AI-assisted body modeling", looping landmark-constellation animation (same asset as MI-12), link → GitBook deep-dive | |
| A6 | For designers | split panel: "Post outfits, get commissioned, get paid" + earnings screenshot | |
| A7 | Open source section | `docker compose up` snippet with copy button · architecture mini-diagram · GitHub + CONTRIBUTING links | copy button ✓ morph |
| A8 | Community | Discord card (member count), roadmap link, CueLABS note | |
| A9 | Cloud vs Self-host table (PRD §3) | feature comparison; Cloud column ends in Try Cloud CTA, OSS column in Self Host (→ docs quickstart) | |
| A10 | Footer | product/docs/community columns · privacy (APP-005) · terms · `privacy.cuesoft.io` clause link · language | |

Analytics events (→ Upstat, D2): `page_view`, `demo_start` (A4 engage),
`github_click` (A1/A7), `try_cloud_click`, `self_host_click`. **[PRD + Directive]**

Docs: hosted on **GitBook** (Git-synced from this `docs/` folder) **[Directive]**;
API reference via **Scalar** rendering the OpenAPI specs (api.md) embedded at
`/docs/api`. **[Proposed]**

## Part B — Web dashboard (app.apparule.cuesoft.io or /app)

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
- Filter chips: style tags, price band, turnaround time, "near me" **[Proposed]**.

### B3 `/app/orders` — Requests & orders (both roles)
- Tabs: **As customer** / **As designer** (designer tab only when creator
  profile enabled).
- `RequestCard` list; status pills (MI-14): `requested → quoted → paid →
  in_progress → shipped → delivered` (+ `declined`, `disputed`, `cancelled`).
- Click → order detail: outfit summary · **measurement snapshot** (the exact
  values sent, immutable) · thread (MI-17) · timeline (MI-14) · payment box
  (MI-15: quote → pay → escrow-held → released on delivery confirm)
  **[Proposed payment model — ratify]**.
- Designer actions per state: quote (price + due date) / decline with reason /
  mark in-progress / mark shipped (tracking optional) ; customer: pay, confirm
  delivery (releases payout), open dispute.

### B4 `/app/vault` — Measurement vault
- Header: freshness ring avatar (MI-11) + "Retake" CTA → capture options
  (webcam upload / phone hand-off QR **[Proposed]** / manual entry MI-13).
- `MeasurementCard` grid (shoulder, hip, +SMPL girths when available) with
  history sparklines; tap → history sheet (sessions list, method chips,
  delete session).
- Consent + retention notice inline (data-model.md §4); "Download my data" /
  "Delete all" links (rights parity with expendit **[Proposed]**).

### B5 `/app/create` — Post an outfit (designer)
- Dropzone (≤10 media, reorder by drag; MI-4 preview) → details form
  (caption, style tags, base price or "quote on request", turnaround days,
  fabric notes) → publish.
- Non-creator users see the creator-profile upsell here ("Become a designer").

### B6 `/app/{username}` — Profiles
- Designer: avatar + story ring, follower/following/posts counts, Follow
  (MI-7), Request CTA, bio, grid/saved tabs; earnings tab visible only to
  self (payout balance, payout account setup, transaction list) **[Proposed]**.
- Regular user: private vault indicator (measurements NEVER public), saved
  looks tab, order history link. Privacy default: vault visible to no one;
  a measurement snapshot is shared **only** inside a request (APP-005 story).

### B7 `/app/settings`
- Account (Google sign-in via Firebase per X-1; `account.cuesoft.io` facade later), creator profile toggle,
  payout account (designer), notifications, privacy & data (export/delete,
  consent history), language, theme.

## Part C — Mobile app (Flutter) — primary surface

Bottom tab bar: **Home · Explore · ➕ · Orders · Profile** (design.md §3).
Existing screens (splash/welcome/auth/capture) remain the entry path.

| # | Screen | Spec |
| --- | --- | --- |
| C1 | Onboarding | existing auth flow; post-signup interstitial: "Take your first measurement" (→C6) or "Explore outfits" — skippable |
| C2 | Home feed | = B1 minus right column; story rail on top; MI-1/2/3/4/5/6/16/18/20 all active |
| C3 | Explore | search + 3-col grid; long-press peek preview (scale 0.97 + dim, MI haptic light); pull-to-refresh MI-5 |
| C4 | Post detail | full-bleed carousel; action row; caption; comments sheet (swipe-up); Request CTA pinned bottom (safe-area) |
| C5 | Request stepper | MI-10 sheet: Step 1 pick measurement set (vault snapshot picker, freshness warnings); Step 2 notes + budget + delivery; Step 3 review → submit; success: confetti + "view order" |
| C6 | Capture | existing guide screens restyled: silhouette overlay + countdown (MI-12); processing constellation; results screen: measurement cards stagger-in, "Save to vault" primary, "Retake" quiet; manual-entry fallback (MI-13) |
| C7 | Vault | = B4 adapted; entry from Profile tab header ring |
| C8 | Orders | = B3 list + detail; push notifications drive re-entry (badge MI-16) |
| C9 | Profile | own: vault ring header, grid of liked/saved, settings gear; others: designer profile = B6 |
| C10 | Notifications sheet | activity list (likes, follows, quotes, status changes); grouped by day; swipe-to-clear |

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
