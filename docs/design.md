# Apparule — Design Language

> Reference feel: **instagram.com** — Apparule is a social network where users
> capture/manage their measurements and designers post outfits; users like,
> save, share, and commission outfits with their measurements attached, and
> designers get paid. This document defines the visual system and the
> microinteraction vocabulary that every page/screen in [pages.md](pages.md)
> draws from. Markers: **[Directive]** = user-stated direction (2026-07-16),
> **[Proposed]** = ratifiable design decision, **[Decided <date>]** = ratified
> decision.

## 1. Design principles

1. **Content is the chrome** — outfit imagery dominates; UI recedes to thin
   bars and overlays (Instagram's core trick). No decorated containers around
   media.
2. **One-thumb first** — every core action (like, save, request) reachable in
   the bottom half of a phone screen; desktop dashboard is an adaptation, not
   the origin.
3. **Measurement data feels personal, not clinical** — the vault is styled
   like a profile feature (cards, avatars, history), not a spreadsheet.
4. **Commerce with social manners** — requests/payments use the same visual
   language as the feed (cards, threads), never a bolted-on checkout look.

## 2. Foundations

### Color **[Proposed]**

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `bg` | #FFFFFF | #000000 | app background (true black dark mode, IG-style) |
| `bg-elev` | #FFFFFF | #121212 | sheets, cards, modals |
| `border` | #DBDBDB | #262626 | hairline dividers (1px) |
| `text` | #111111 | #FAFAFA | primary text |
| `text-2` | #737373 | #A8A8A8 | secondary/meta |
| `accent` | #E1306C→#F77737 gradient | same | the "Apparule gradient" — story rings, primary CTAs, active states (IG gradient adapted; final hues from brand pass). In Figma the token is two variables, `accent-start` + `accent-end` — gradient stops can't bind a single variable (§7) **[Decided 2026-07-17]** |
| `on-accent` | #FFFFFF | #FFFFFF | text/icons on `accent`-gradient and destructive fills — replaces raw white in those contexts (exception: on-media capture UI stays raw white by design) |
| `link` | #00376B | #E0F1FF | usernames, links |
| `like` | #ED4956 | #ED4956 | heart active |
| `success/warn/error` | #2E7D32 / #B26A00 / #C62828 | brightened equivalents | order states, payment states |
| `accent-text` | #DB2967 | #E73771 | AA text variant — readable text in the accent binds this (final-CTA pill on `on-accent`, active measure value); gradient fills/rings/icons keep `accent-start`/`accent-end`. Derived in OKLCH (L only) from `accent-start` to clear 4.5:1 on `bg`/`bg-elev` |
| `success-text/warn-text/text-2-text` | #27772C / #985A02 / #696969 | #4ECB71 / #FFB020 / #A8A8A8 | AA text variants for the chip/pill recipe (`text-X` on `bg-X/14`) and plain status text — readable text binds the `-text` variant, fills/borders/icons keep the base hue. Light values darken the base in OKLCH until ≥4.5:1 on the hue's 14% tint; dark base values already clear it, so the dark variants alias them. `error` needs no variant (4.50 on its light tint) |
| Afrocentric pattern | 4–6% opacity geometric line pattern | — | section backgrounds on home page + empty states only (PRD §2 nuance without noise) |

### Type

- Family: **Inter** on app and marketing surfaces — the family the Figma
  library's type styles render, so live type weight/width match the canvas on
  every platform (web self-hosts it via `next/font` with the system stack as
  fallback). A display serif/geometric for the public home hero remains a
  brand-pass option. **[Decided 2026-07-20 — font-weight audit vs the Home
  frame; sibling products already ship Inter]**
- Scale: 12 / 13 / 14 (base) / 16 / 20 / 24 / 32. Weights 400/600/700.
  Tracking: Title/24 −0.25px, Display/32 −0.5px, all smaller sizes 0 (the
  type styles pin these). Usernames 600; numerals tabular for measurements
  and money.

### Layout

- Mobile: single column, media full-bleed; bottom tab bar (5 slots); safe-area
  aware.
- Desktop dashboard: IG-desktop pattern — slim left icon rail (72px, expands
  to 244px on ≥1264px) + centered content column (max 630px feed / 935px
  profile) + right meta column where useful.
- Marketing (public home): a single centered content container — 1080px wide
  at 1440, 24px minimum gutters, full-bleed backgrounds only; every section's
  inner content aligns to it. **[Decided 2026-07-19]**
- Media ratios: 1:1 default, 4:5 portrait max in feed (IG rules); carousels up
  to 10 images.
- Radii: 8px cards/sheets, full-round avatars/pills. Hairline borders over
  shadows; shadows only on floating layers (sheets, popovers).

### Iconography & imagery

- 24px stroke icons (outline default, filled = active state — IG convention).
- Avatars: 32 (lists) / 44 (bars) / 56 (story ring context) / 96+ (profiles).
- Story-ring gradient reserved for: designers with new outfits, and the
  user's own "measurement freshness" ring (see §4.6). **[Proposed]**


### Shared foundations (ecosystem parity — identical across the three products)

| Foundation | Value |
| --- | --- |
| Spacing scale | 4px base grid: `4 / 8 / 12 / 16 / 24 / 32 / 48 / 64` — no off-scale values; component padding uses the scale, not arbitrary numbers |
| Breakpoints | `sm 640 · md 768 · lg 1024 · xl 1280 · 2xl 1536` (Tailwind-aligned); mobile-first media queries |
| Motion durations | `fast 120ms · base 200ms · slow 300ms · entrance 250ms` — MI specs quote exact values, these are the defaults |
| Motion easing | standard `cubic-bezier(0.2, 0, 0, 1)`; exit `cubic-bezier(0.4, 0, 1, 1)`; springs only where an MI names one |
| Z-index layers | `base 0 · sticky 10 · dropdown 20 · overlay 30 · sheet/modal 40 · toast 50` — nothing outside these six |
| Iconography | **Lucide** (24px stroke default) everywhere; product-specific icons only as approved additions in the Figma Style Guide |
| Focus states | 2px accent ring, 2px offset, `:focus-visible` only — identical rule all products |
| Radii (product) | 8px cards/sheets, full-round avatars/pills |
| Product note | haptics per MI-20 |

- **Cursor affordance**: enabled interactive controls show `cursor: pointer` — one base-layer rule on `button:not(:disabled)`, `[role="button"]:not([aria-disabled="true"])`, `select:not(:disabled)`, `summary`, `label[for]`; links use the native pointer; disabled controls keep the default cursor. [Directive 2026-07-19]

These rows are standardized in the org SKILL.md — a change here is an
ecosystem change, PR'd to all three design.md files together.

## 3. Component inventory (shared)

| Component | Anatomy | Notes |
| --- | --- | --- |
| `PostCard` | header (avatar, username, badge, ⋯) · media carousel · action row (♥ 💬 ↗ ⌁save) · like count · caption (2-line clamp, "more") · request CTA · timestamp | The request CTA ("Request this outfit") is Apparule's one addition to the IG anatomy — a full-width quiet button under the action row on designer posts |
| `StoryRail` | horizontal scroll of gradient-ringed avatars | reused as "fresh outfits" rail |
| `RequestCard` | outfit thumb · status pill · designer/customer · price · next-action button | states in §4.4 |
| `MeasurementCard` | metric name · value + unit (tabular) · source chip (scan/manual) · sparkline of history | tap → history sheet |
| `Sheet` | bottom sheet mobile / centered modal desktop | all secondary flows live in sheets |
| `TabBar` | Home · Explore · ➕ Create · Orders · Profile | Create is a raised gradient FAB-in-bar |
| `Toast` | icon + text, bottom, auto-dismiss 3s | optimistic-action failures re-toast with Retry |
| `EmptyState` | pattern-bg illustration + one-line + one CTA | every list defines one |
| `Skeleton` | shimmer blocks matching final layout | feed: header line + square + action row |

## 4. Microinteraction catalog

Numbered so pages.md can reference them as `MI-n`.

| ID | Interaction | Spec |
| --- | --- | --- |
| MI-1 | **Double-tap to like** | double-tap media → 96px heart scales 0→1.2→1 with 8° tilt, fades 300ms; action-row heart fills simultaneously; count ticks +1 with 120ms slide-up; haptic light (mobile). Optimistic; rollback re-empties heart + error toast |
| MI-2 | **Like button** | tap: scale 1→0.8→1.15→1 (240ms spring), outline→filled `like` red; unlike: no animation (IG asymmetry) |
| MI-3 | **Save/bookmark** | icon dips -4px then fills; first-ever save shows "Saved to your looks" toast with link |
| MI-4 | **Carousel** | horizontal snap, 1px progress dots (active dot 6px, gradient); desktop: hover chevrons; edge-resist bounce at ends |
| MI-5 | **Pull-to-refresh** | gradient spinner grows with pull distance (threshold 72px), haptic on trigger |
| MI-6 | **Infinite scroll** | prefetch at 3 cards from end; skeleton x2 during fetch; "You're all caught up ✓" divider after 48h-old content (IG pattern) |
| MI-7 | **Follow button** | "Follow" gradient-filled → on tap morphs 150ms to quiet "Following"; unfollow via confirm sheet (prevents accidental) |
| MI-8 | **Story ring** | 2px gradient ring; consumed → 1px `border` gray; subtle 1.5s rotation on ring while loading content |
| MI-9 | **Share** | native share sheet (mobile) / copy-link popover (desktop); post flashes 1px gradient border 400ms on copy |
| MI-10 | **Request stepper** | 3-step sheet (Measurements → Notes/Budget → Review); progress bar fills with 300ms ease; step transitions slide 24px; final CTA shows inline spinner then ✓ morph + confetti burst ≤ 800ms (once per order) |
| MI-11 | **Measurement freshness ring** | vault-header avatar ring: gradient if measured <30d, amber 30–90d, gray >90d; tooltip "Measured 12 days ago — retake?" — the ring is a vault affordance; profile avatars, including the viewer's own B6 profile, render plain **[Decided 2026-07-20]** |
| MI-12 | **Capture flow** | camera overlay silhouette guide pulses gently; countdown 3-2-1 rings; processing state: landmark constellation animates over photo (the "AI is working" moment — also the SMPL demo asset); results cards stagger-in 60ms apart |
| MI-13 | **Manual measure input** | tape-measure themed slider + numeric field; value change animates sparkline preview; unit toggle cm/in flips with 3D x-rotation 200ms |
| MI-14 | **Order status pill** | status changes pulse once (scale 1→1.06→1) + color crossfade; timeline dot draws its connector line 400ms |
| MI-15 | **Payment states** | pay button → inline spinner → shield-check morph; escrow explainer expands beneath on first payment |
| MI-16 | **Badge counts** | Orders tab badge increments with springy scale; clears on tab visit |
| MI-17 | **Typing/response** | request thread shows designer "responding…" three-dot pulse |
| MI-18 | **Optimistic everywhere** | likes, saves, follows, comments post instantly; server failures roll back with toast — never blocking spinners on social actions |
| MI-19 | **Skeleton shimmer** | 1.2s linear shimmer, 8% white overlay; never longer than 3 cycles before error state |
| MI-20 | **Haptics (mobile)** | light: like/save; medium: request submitted, payment success; error buzz: capture failed |

## 5. Accessibility & motion rules

- All MI animations respect `prefers-reduced-motion` (fall back to opacity
  crossfades ≤150ms).
- Hit targets ≥44px; action row icons 24px with 12px padding.
- Like/save state changes announced via aria-live polite ("Liked. 214 likes").
- Contrast: `text-2` on `bg` ≥ 4.5:1 both themes; gradient CTAs carry
  `on-accent` (#fff) text with 4.5:1 minimum against mid-gradient.
- Media requires alt text at post creation (designer prompt, skippable with
  default "Outfit by {designer}").

## 6. Platform parity map

| Surface | Now | Target |
| --- | --- | --- |
| Home (public) | template stub | §pages.md Part A |
| Dashboard (web app) | — | §pages.md Part B — same IA as mobile, desktop-adapted |
| Mobile (Flutter) | auth + capture screens | §pages.md Part C — the primary social surface |

Component naming is shared across web/Flutter (PostCard ⇄ `post_card.dart`)
so design tokens and specs translate 1:1. **[Proposed]**

## 7. Figma Style Guide (source of truth for tokens)

The design system lives in the product's Figma file on a dedicated **Style
Guide** page, backed by a variable collection **`apparule/tokens`** with **true Light and Dark modes** (migrated 2026-07-16 after the pro upgrade; the earlier light/dark-group workaround is retired — components bind one token and switch by mode). The collection also carries the foundations as variables: spacing scale, radii, durations, z-index. Every color token in §2 exists as a Figma
variable (scopes: frame/shape/text fills + strokes) so designs bind to tokens,
never raw hexes; the Style Guide page renders swatches (both modes), the type
scale, and status/accent samples. Token changes happen in Figma first, then
sync back into this document — the two must never diverge. Local type styles
(11), a component Samples frame, and the grid styles (`Grid/Feed 630`,
`Grid/Profile 935`) now exist (2026-07-17); the numeric text styles in the
`tnum` note below are the actual next Style Guide iteration.

`on-accent` (§2) now exists in the collection (added 2026-07-16, both modes)
— components on gradient/destructive fills bind it instead of raw white.

`accent` (§2) is implemented as two variables, `accent-start` + `accent-end`:
Figma cannot bind a gradient stop's color to a single variable, so the
gradient binds its two stops to these (also noted on the file's "About this
library" card) **[Decided 2026-07-17]**.

Numeric type-style note: OpenType tabular figures (`tnum`) must be enabled
manually in the Figma UI — the plugin API cannot set OpenType font features.
It applies to the numeric styles `Display/32 Bold`, `Title/20 Semi Bold`, and
`Body/16 Semi Bold` wherever they render measurement values and money.

**Style Guide page refresh (in progress, 2026-07-17).** The rendered page
drifted from the collection and is being brought back in line: adding the
missing `on-accent` swatch, replacing the stale "light/ + dark/ groups"
subtitle with the true-modes wording, correcting the type-scale sample labels
to the real local style names (`Title/20 Semi Bold`, `Body/16 Semi Bold`,
`Caption/13 Regular`, `Micro/12 Regular`, plus the ramp entries the samples
omit), and rendering the z-index layer row. Per the rule above, the page and
this document must never diverge.

## 8. Figma component build plan (design phase)

> The Figma work order. Foundation = the `apparule/tokens` collection +
> Style Guide page (already live, §7). Components become Figma components
> with variants exactly as listed; screens assemble from instances only.

**Canvas hygiene [Directive 2026-07-18].** Design canvases carry **product
copy only** — text a user would actually see. Spec annotations (MI
references, requirement IDs, implementation notes) live in component
descriptions and in these docs, never on the screens themselves.

### 8.1 Build order

| Stage | Build | Unlocks |
| --- | --- | --- |
| 0 Foundations | type styles from §2 scale · Lucide icon set import (extended 2026-07-16 — see icon note below) · grid styles (630/935 columns) | everything |
| 1 Atoms | Button, Input (incl. textarea + currency kinds, §8.2b), Pill/Chip, Avatar, IconButton, Toast · **atom completions (2026-07-16)**: GoogleAuthButton, Switch, Tooltip, Spinner | all molecules |
| 2 Molecules | StoryRail item, action row, MeasurementCard, StatusPill set, TabBar, Sheet chrome · **form kit**: FormRow, AddressFieldset (request-stepper delivery + profile location, X-10 tier 1) · **capture kit**: CaptureOverlay, CountdownRing, QCHintChip, ProcessingConstellation, CaptureResults chrome, ManualMeasureRow, CaptureOptionCard · **chrome kit (2026-07-16)**: NavRail, AppBar, Tabs · **form kit II (2026-07-16)**: Select/OptionRow, DateInput, MediaDropzone/MediaUploadTile, Banner/InlineAlert, Popover/MenuItem | cards |
| 3 Cards | PostCard, RequestCard, NotificationRow, CommentRow, ThreadBubble, EmptyState set, Skeletons · **social rows (2026-07-16)**: GridTile, UserRow, CaughtUpDivider · **order kit (2026-07-16)**: OrderTimelineRow, PaymentBox · **vault rows (2026-07-16)**: SessionRow/SnapshotPickerRow · **ops & earnings rows (2026-07-16)**: ModerationQueueRow, EarningsSummary + TransactionRow | screens |
| 4 Screen templates | feed, post detail, request stepper (3 steps), vault, capture overlays, orders list+detail, profile ×2, moderation queue · **added 2026-07-16 (all v1 per pages.md)**: explore, create/composer, settings, auth/onboarding, notifications · **added 2026-07-18 (iteration 1)**: designer onboarding/KYC, earnings & payouts, dispute flow, decline sheet, followers/following, explore search-results, settings sub-screens ×3, comments full sheet (pages.md B8/B9, C11–C14 + flow lines) | mobile + dashboard designs |
| 5 Home page | A1–A10 sections (pages.md Part A) + iteration rows A4b · A7b · A7c · A9b · A9c (2026-07-18) · **marketing kit (2026-07-16)**: MarketingNav + MarketingFooter, Home section kit (§8.2b) | landing design |

**Stage 0 icon note — extended set (2026-07-16).** Beyond the original
import, the parity audit requires these Lucide glyphs: `shield-check` (MI-15
pay morph, PaymentBox escrow-held) · `more-horizontal` (PostCard ⋯ overflow,
moderation/action menus) · `chevron-down` (Select trigger, expandable
snapshot values in stepper review, caption "more") · `calendar` (quote
due-date, stepper target date) · `sun` + `moon` (NavRail theme toggle; `moon` also seeds the marketing-nav `ThemeToggle` master, [Directive 2026-07-19]) ·
`copy` (MI-9 desktop copy-link popover; A7 snippet copy) · `alert-triangle`
(freshness/turnaround soft warnings, KYC-lapse banner, dispute states) ·
`info` (escrow explainer, consent/retention notice, "near me" explainer) ·
`trash-2` (delete session, "Delete all") · `upload` or `image-plus` (create
media dropzone) · `map-pin` (profile location, "near me" filter) · `wallet`
(earnings/payout surfaces) · `clock` (deadline chips: quote expiry, due
dates, auto-refund countdowns) · `flag` (report post/comment, SOC-009) ·
`log-out` (settings sign-out) · `grid-3x3` (the Tabs grid-view icon
variant). Brand glyphs — the Google 'G' for the X-1
auth CTA, the GitHub mark (home page), and others as needed — are **not
Lucide**: they enter as approved additions per the shared-foundations
iconography rule (§2).

**Stage 4 screen-state rule [Directive 2026-07-18].** Every data-driven
screen template ships **three frames**: default, empty (EmptyState + its
first-run copy; demo-data toggle where a flow specs one), and loading
(Skeleton). A template isn't done until all three exist. **As built
(2026-07-18 QA loop):** the rule is met on the core data-driven templates —
default / empty / loading frames exist across feed, explore, vault, orders,
and notifications, and their dashboard equivalents.

**Naming standards (canonical across the three products) [Decided
2026-07-17].** Component sets are PascalCase; variant property names are
lowercase (`kind`, `size`, `state`, …). Icons are named `icon/<lucide-slug>`
(e.g. `icon/heart`, `icon/chevron-down`); brand glyphs are
`icon/brand-<name>` (e.g. `icon/brand-google`). Apparule's existing capital
`Icon/*` prefix is being renamed to lowercase `icon/*` to match this
canonical scheme. The single auth CTA component (X-1) is named
`GoogleAuthButton` in every product.

### 8.2 Variant matrices (the component contracts)

> **Contract/build reconciliation (2026-07-17).** `theme ×2` in these rows
> (and §8.2b) is satisfied by the `apparule/tokens` true Light/Dark variable
> modes (§7) — components carry **no** theme variant axis; dark/light QA runs
> on the preview frames. Rows marked *(as built 2026-07-17)* were built ahead
> of a contract row; their built axes are the contract.

| Component | Variants × states |
| --- | --- |
| Button | kind: gradient-primary / quiet / destructive / link · size: md 44 / sm 36 · state: default / pressed / disabled / loading · theme ×2 |
| Input | text / numeric+unit-toggle (cm-in) / search · state: default / focus / error / disabled · theme ×2 |
| Avatar | size: 32 / 44 / 56 / 96 · ring: none / gradient (fresh) / amber / gray · badge: none / designer-verified |
| Chip | kind: default / selected / removable — the §8.1 "Pill/Chip" atom *(as built 2026-07-17)* |
| IconButton | size: md / sm · state: default / pressed / disabled *(as built 2026-07-17)* |
| PostCard | media: single / carousel (dots) · CTA: with / without "Request this outfit" · state: default / skeleton · theme ×2 |
| StoryRail item | state: unseen (gradient) / seen (gray) / loading (rotating) |
| ActionRow | liked: false / true · saved: false / true — the PostCard action row (MI-1/MI-2/MI-3) *(as built 2026-07-17)* |
| RequestCard | status pill: requested / quoted / paid / in_progress / shipped / delivered / refunded / declined / disputed / cancelled · role: customer / designer view |
| StatusPill | the 10 order states + freshness (fresh/aging/stale) · **[Decided 2026-07-16]** order-state → token mapping: quoted/shipped → `link` · paid/delivered → `success` · in_progress/refunded → `warn` · declined/disputed → `error` · requested/cancelled → `text-2` |
| MeasurementCard | source: scan / manual · confidence: normal / low (<0.7 chip) · with/without sparkline |
| TabBar | active tab ×5 · Orders badge: none / count |
| Sheet | mobile bottom / desktop modal · with/without stepper header · size: default 480 / wide 896 (viewport-clamped — post detail opens wide) |
| EmptyState | feed / vault / orders / explore / notifications (5 illustrated) |
| Toast | success / error+retry / neutral |
| Skeleton | kind: line / avatar / media / card (§3 anatomy; MI-19 shimmer) *(as built 2026-07-17)* |
| CaptureOverlay | guide: searching (silhouette pulses) / aligned (guide turns success) / countdown / qc-hint (chip slot) · pose: front / side (M-10 — the side pose swaps in the right-profile silhouette, arms relaxed) — dashed silhouette vector over camera viewport (MI-12) |
| CountdownRing | 3 / 2 / 1 (ring progress + numeral) |
| QCHintChip | code ×12: no_body / multiple_bodies / partial_body / undecodable_image / low_resolution / poor_lighting / blurry / not_frontal / camera_tilt / arms_position / too_far / not_side_profile (side pose, M-10) — one actionable guidance line each, `arms_position` copy per pose (fail codes [capture-qc.md](capture-qc.md) §1–2; canonical copy [flows/vault.md](flows/vault.md) QC-failures row) |
| ProcessingConstellation | state: processing (landmark constellation over photo) / success / failed — the "AI is working" moment (MI-12) |
| CaptureResults chrome | header (confidence summary) + MeasurementCard stagger list slot + "Save to vault" gradient / "Retake" quiet (pages.md C6) |
| ManualMeasureRow | tape-measure slider + numeric field + cm/in toggle · state: default / active / error (MI-13) |
| CaptureOptionCard | mode: webcam-upload / manual-entry (vault "Retake" options, pages.md B: vault header) |
| FormRow | label + control + helper/error · state: default/focus/error/disabled (profile & settings editors) |
| AddressFieldset | context: delivery (request stepper — frozen per order) / profile location (city + state + country · "near me" explainer, X-10 tier 1) · NG-state select · prefill-from-last-order |

### 8.2b Completion pass (2026-07-16)

Contract rows surfaced by the component parity audit of
[pages.md](pages.md), the flow docs,
[order-lifecycle.md](order-lifecycle.md) and
[capture-qc.md](capture-qc.md) against §8.2. Same contract rules as §8.2
(screens assemble from instances only; `theme ×2` is delivered by the
`apparule/tokens` Light/Dark modes, not a variant axis — see the §8.2
preamble); grouped by kit. Marketing rows are
Stage 5 and non-blocking; everything else feeds Stages 1–4.

**App chrome & navigation**

| Component | Variants × states |
| --- | --- |
| NavRail | width: collapsed 72 / expanded 244 (≥1264px) · item ×7 (Home / Explore / Create / Orders / Vault / Profile / Settings) × state: default / active / hover · footer slot: theme toggle + support link · theme ×2 · **as built (2026-07-17):** decomposed into `NavRail` (width ×2) + child set `NavRailItem` (expanded ×2 × state ×3) |
| AppBar | kind: root (title/logo + action slot) / sub (chevron-left + title + trailing action) / over-media (transparent) · theme ×2 |
| Tabs | kind: text ×2 items ("As customer / As designer") / icon (grid · saved) · state: active / inactive · underline indicator · theme ×2 · **as built (2026-07-17):** `active: first / second` (which item is active) × `kind: text / icon` — semantically the same states, different property shape; the grid glyph moves from an interim inline vector to `icon/grid-3x3` (§8.1) |

**Form & overlay primitives**

| Component | Variants × states |
| --- | --- |
| GoogleAuthButton | the single auth CTA (X-1): Google 'G' mark + "Continue with Google" · state: default / pressed / loading / disabled · theme ×2 |
| Select / OptionRow | trigger: default / focus / error / disabled · OptionRow: default / selected (radio · check) · contexts: decline-reason enum, dispute reason picker, NG-state, bank (KYC), language · theme ×2 |
| DateInput | state: default / focus / error / disabled · calendar popover · min-date rules (due_at ≥ today+1; target date ≥ today+turnaround soft-warn) · theme ×2 · **as built (2026-07-17):** the calendar popover is a standalone `DatePickerPopover` component — per the 87:1035 master: Sunday-first week, blank outside-month cells, border-ring on today (2026-07-20) |
| Input (extends §8.2) | + kind: textarea (multiline, 0–500 counter) / currency (₦ prefix, tabular numerals) · state: default / focus / error / disabled · theme ×2 |
| MediaDropzone | state: empty (drop target) / uploading (progress) / error (size · type) · MediaUploadTile: thumb ×≤10 · drag-reorder handle · alt-text indicator · remove · theme ×2 |
| Banner / InlineAlert | tone: info / warn / error / success · persistent / dismissable · action-link slot (Retry, support, explainer) · theme ×2 |
| Popover / MenuItem | item: default / destructive / with-icon · contexts: PostCard ⋯ overflow (report/share), copy-link (MI-9 desktop), recent-searches dropdown · desktop popover / mobile rows-in-Sheet · theme ×2 |
| Switch | state: on / off × enabled / disabled · theme ×2 |
| Tooltip | placement: top / bottom · single-line · theme ×2 |
| Spinner | size: 20 inline / 28 refresh · kind: gradient (pull-to-refresh, grows with pull — MI-5) / neutral · theme ×2 |

**Product rows (feed · orders · vault · moderation · earnings)**

| Component | Variants × states |
| --- | --- |
| GridTile | ratio 1:1 · state: default / hover-stats (♥ + 💬 counts overlay, 120ms fade) / skeleton · corner badge: none / carousel · theme ×2 |
| UserRow | avatar 32/44 + username + meta line · trailing: Follow (gradient) / Following (quiet) / none (MI-7 morph) · theme ×2 |
| CaughtUpDivider | "You're all caught up ✓" — check glyph + hairline pair (MI-6) · theme ×2 |
| OrderTimelineRow | dot: done / current (pulse 1→1.06→1) / pending / terminal-error · connector: drawn / undrawn (MI-14, 400ms line draw) · label + timestamp · theme ×2 |
| PaymentBox | state: quoted (pay CTA) / paying (spinner) / escrow-held (shield-check + first-payment explainer expand) / released / refunded / dispute-frozen (MI-15) · role: customer / designer · itemized 10% fee line · theme ×2 |
| ThreadBubble | side: sent / received · content: text / image attachment (images only, [order-lifecycle.md](order-lifecycle.md) §5) · state: sending / sent / failed · typing variant: three-dot "responding…" pulse (MI-17) · theme ×2 · **as built (2026-07-17):** typing folds into `content: text / image / typing` (13 children — not the full 2×3×3 matrix; the send-state axis doesn't apply to typing) |
| CommentRow | avatar 32 + username + text + timestamp + like heart · state: default / liked / posting-optimistic (MI-18) / reply-indent · theme ×2 |
| NotificationRow | kind: like / follow / comment / quote / status-change / payout · state: unread / read · trailing: post thumb / Follow button / none · theme ×2 |
| SessionRow | context: history (date + method chip + values + per-session CSV/PDF export controls + delete — the vault history sheet exports one session per file, F2-9) / picker (radio select + freshness warning: fresh / aging / stale) · state: default / selected · theme ×2 **[Revised 2026-07-19]** |
| ModerationQueueRow | subject preview: post/comment thumb + reporter context · reason · actions: hide_post / suspend_account / dismiss · state: open / actioned (audit: actioned_by) · theme ×2 |
| EarningsSummary | balance (released) / pending (held escrow) cards · TransactionRow: kind payout / escrow-held / fee-line (10%) · amount tabular + provider ref · theme ×2 |
| EmptyState (extends §8.2) | + capture/camera-permission-denied: explainer + settings deep-link + "enter manually instead" |

**Marketing (home page, Stage 5)**

| Component | Variants × states |
| --- | --- |
| MarketingNav / MarketingFooter | nav: logo + 4 text links (Features · For designers · Docs · GitHub — the GitHub item renders as a compact star badge: GitHubMark(14) + star glyph(12) + neutral "Star" label (fleet-wide construction, reconciled 2026-07-20)) + `ThemeToggle` + "Sign in" text link (`/signin`) + "Try Cloud" gradient-primary CTA · state: top / stuck-blurred · footer: brand block (wordmark + tagline) + 4 pinned link columns — Product (Features · Try Cloud · Self Host · For designers) · Docs (Docs · Quickstart · API reference · Self-host guide) · Community (GitHub · Discord · Roadmap · CueLABS™) · Legal (Privacy · Terms · Status) — + legal bar `© Cuesoft Inc. 2026. Apparule. CueLABS™ Division. MIT License.` with security-policy link (SECURITY.md) + English language selector · theme ×2 · **[Directive 2026-07-19]:** built to the cross-product "Marketing nav, footer & theme parity canon" (generator SKILL.md) — one link inventory across apparule/expendit/upstat, rendered in apparule's light 4-column design, with the `ThemeToggle` master; all hrefs are the canon's canonical URLs · **[Revised 2026-07-19]:** the nav's GitHub star badge is neutral on canvas — GitHubMark + star glyph + "Star" label, no count (the live star count is runtime behavior; masters carry no invented numbers — accuracy standard below) |
| Home section kit | StatCard ×3 (fade-up) · WalkthroughStep (screenshot + 2 lines + step dots) · ComparisonTable (Cloud vs OSS + CTA row) · CodeSnippetBlock (copy → ✓ morph; `tabs: none / docker / helm` — the A7c self-host block ships the mirrored **Docker Compose \| Helm** tab pair, only the final command differing **[Ratified 2026-07-20]**) · CommunityCard (Discord member count) · **status (2026-07-17):** the one remaining unbuilt Stage-5 row (MarketingNav/MarketingFooter are done) — in build now; contract stays live, not deferred · **as built (2026-07-18):** WalkthroughStep step dots corrected to ×4 (the A4 walkthrough's four steps; the active dot is set per instance) · the CommunityCard master carries a neutral badge — no member count (accuracy standard below) |
| FAQItem | question + chevron · state: collapsed / expanded · one-open-at-a-time group, rows deep-linkable (pages.md A9b) · theme ×2 · **as built (2026-07-18):** ≈720px accordion row; chevron rotates 180° on expand/collapse (`base` 200ms) — the iteration addition the note below anticipated |

*Accuracy standard (2026-07-18):* the marketing stat band (StatCard ×3,
pages.md A3) carries **product claims only** — ±2 cm target accuracy · 2
photos · 30-day photo auto-delete — never invented research statistics; the
same rule keeps master badges neutral (no star or member counts on canvases).

*Iteration note (2026-07-18):* the home FAQ section (pages.md A9b) implies a
`FAQItem` accordion row (question · expanded/collapsed · one-open-at-a-time
group) — the build may add it to this kit; annotate the contract row here as
an iteration addition once the build report confirms it. **Confirmed
(2026-07-18):** the build added it — the `FAQItem` row above is the as-built
contract.

*As-built fixes (2026-07-18 QA loop):* three master corrections from the QA
pass — `Sheet`: the master's slot strokes are removed (slots render clean in
instances); `Input` textarea kind: inner text-area height fixed;
`RequestCard`: the title truncates to 1 line (ellipsis) so the price is
always visible.

*As-built (2026-07-19):* the Home frame's sections all sit on the §2
marketing container (1080px at 1440, x 180–1260) — nav, footer, the A4
walkthrough, A4b deep-dives, A7b topic rows, and the stat band included;
right-column visuals (hero phone, constellation, earnings block,
architecture diagram) right-align to the container edge. Full-bleed section
backgrounds (e.g. the A9c CTA band) stay 1440.

### 8.3 Design-prep needed from content

Outfit photography for realistic feed mocks is **sourced** (2026-07-16):
CC-licensed stock via Openverse/Wikimedia Commons, curated for provenance
(no conflict-related archive imagery), attributions kept on the Figma
Assets page — the attribution grid is maintained (every image keeps its
caption). Still needed: hero H1 copy (prd §8.6); the Afrocentric pattern
asset (§2) at 3 opacities.

### 8.4 Prototype (built 2026-07-18)

> The click-through layer wired over the Stage-4/5 frames, and the standard
> it follows **[Decided 2026-07-18]**. Prototype wiring is part of "done"
> for a flow the same way the §8.1 three-frame rule is for a screen.

**Named flows (starting points per page).** Every prototype flow has a named
starting point on its Figma page:

- **Mobile** — "Onboarding → first order" starting at C1 (pages.md Part C),
  plus separate state starts for the designer onboarding/KYC, payout,
  dispute, and decline paths.
- **Dashboard** — "Feed" (B1), plus starts for the moderation, decline,
  creator-upsell, and payout states.
- **Home** — "Marketing site" (Part A), whose CTA hands off cross-page into
  the app flow.

**Wiring conventions.**

- Reactions are `ON_CLICK` → `NAVIGATE` between top-level frames.
- Transitions: `DISSOLVE` ~150–200ms for nav/tab switches; `SMART_ANIMATE`
  for pushes and backs; `AFTER_TIMEOUT` for async verification states
  (e.g. processing → results), which advance on their own.
- Empty, loading, QA, and index frames stay **out** of the flow by design —
  they exist for the §8.1 screen-state rule and for QA, not for wiring; the
  prototype walks real user paths only.

**Reachability.** Verified by BFS over the reaction graph from each flow's
starting point: every wired frame is reachable, and there are no dead ends
besides intentional terminals.

**Cross-page links (move-wire-restore).** The plugin API rejects creating a
cross-page `NAVIGATE` reaction outright, but an existing reaction persists
across page moves — so cross-page links (the Home CTA handoff) are wired by
temporarily moving the source frame to the destination page, adding the
wire there, and moving the frame back.
