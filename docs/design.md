# Apparule — Design Language

> Reference feel: **instagram.com** — Apparule is a social network where users
> capture/manage their measurements and designers post outfits; users like,
> save, share, and commission outfits with their measurements attached, and
> designers get paid. This document defines the visual system and the
> microinteraction vocabulary that every page/screen in [pages.md](pages.md)
> draws from. Markers: **[Directive]** = user-stated direction (2026-07-16),
> **[Proposed]** = ratifiable design decision.

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
| `accent` | #E1306C→#F77737 gradient | same | the "Apparule gradient" — story rings, primary CTAs, active states (IG gradient adapted; final hues from brand pass) |
| `link` | #00376B | #E0F1FF | usernames, links |
| `like` | #ED4956 | #ED4956 | heart active |
| `success/warn/error` | #2E7D32 / #B26A00 / #C62828 | brightened equivalents | order states, payment states |
| Afrocentric pattern | 4–6% opacity geometric line pattern | — | section backgrounds on home page + empty states only (PRD §2 nuance without noise) |

### Type

- Family: system stack (`-apple-system, Roboto, …`) on app surfaces; a display
  serif/geometric (brand pass) only on the public home page hero. **[Proposed]**
- Scale: 12 / 13 / 14 (base) / 16 / 20 / 24 / 32. Weights 400/600/700.
  Usernames 600; numerals tabular for measurements and money.

### Layout

- Mobile: single column, media full-bleed; bottom tab bar (5 slots); safe-area
  aware.
- Desktop dashboard: IG-desktop pattern — slim left icon rail (72px, expands
  to 244px on ≥1264px) + centered content column (max 630px feed / 935px
  profile) + right meta column where useful.
- Media ratios: 1:1 default, 4:5 portrait max in feed (IG rules); carousels up
  to 10 images.
- Radii: 8px cards/sheets, full-round avatars/pills. Hairline borders over
  shadows; shadows only on floating layers (sheets, popovers).

### Iconography & imagery

- 24px stroke icons (outline default, filled = active state — IG convention).
- Avatars: 32 (lists) / 44 (bars) / 56 (story ring context) / 96+ (profiles).
- Story-ring gradient reserved for: designers with new outfits, and the
  user's own "measurement freshness" ring (see §4.6). **[Proposed]**

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
| MI-11 | **Measurement freshness ring** | profile avatar ring: gradient if measured <30d, amber 30–90d, gray >90d; tooltip "Measured 12 days ago — retake?" |
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
- Contrast: `text-2` on `bg` ≥ 4.5:1 both themes; gradient CTAs carry #fff
  text with 4.5:1 minimum against mid-gradient.
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
Guide** page, backed by a variable collection **`apparule/tokens`** with
**Light** and **Dark** modes. Every color token in §2 exists as a Figma
variable (scopes: frame/shape/text fills + strokes) so designs bind to tokens,
never raw hexes; the Style Guide page renders swatches (both modes), the type
scale, and status/accent samples. Token changes happen in Figma first, then
sync back into this document — the two must never diverge. Type styles and
component samples are the next Style Guide iteration.
