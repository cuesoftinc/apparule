# Changelog

All notable changes to Apparule are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Mobile iOS flavor pass (M-7 completes on iOS): `dev`/`prod` shared
  schemes over `Debug/Release/Profile-{dev,prod}` build configurations
  per Flutter's flavor convention, each layering a flavor xcconfig
  (`ios/Flutter/{dev,prod}.xcconfig`) over its mode base — iOS has no
  `applicationIdSuffix` mechanism, so `PRODUCT_BUNDLE_IDENTIFIER` is
  spelled per flavor (`io.cuesoft.apparule.dev` on dev, bare on prod),
  alongside the per-flavor display name (Apparule Dev / Apparule).
  `flutter build ios --simulator --debug --flavor dev -t
  lib/main_dev.dart` now bundles the dev-scoped `assets/seed/` entries
  (verified in the built `.app`) — the flavorless raw-`xcodebuild` path
  shipped fakes with EMPTY seed. iOS deployment target 13.0 → 15.0
  (Firebase iOS SDK 12 requires iOS 15; docs §2 + M-1 amended); the
  generated `FlutterGeneratedPluginSwiftPackage` inherits the floor from
  the project on every `flutter build ios`
  (`SwiftPackageManager.updateMinimumDeployment`), so no generated file
  is hand-patched. CI grows a `mobile-ios` lane (macos runner, unsigned
  dev-flavor simulator build + a bundled-seed assertion) so iOS breakage
  surfaces at PR time.
- Mobile display-cutout regression harness: `test/helpers/notched.dart`
  reshapes the test view like the live devices and
  `expectContentClearOfTopInsets` asserts under BOTH platform inset
  profiles — the iPhone 17 Pro notch (59px, 34px home indicator) and an
  Android punch-hole status bar (39px) — failing any suite whose
  text/icons/tappables render inside the top inset. Wired into all 24
  screen widget-test suites (the C6 suite asserts the sub-bar height
  step AND the immersive viewfinder). One notched golden per shell
  chrome kind (root bar · sub bar · immersive over-media) pins the
  inset rendering instead of duplicating every screen golden.

- Mobile QA convergence (screens phase 3 closer — the Figma↔code audit
  loop applied to the complete C-series app; canvas file
  `34GbYXm8TpxMMUaAGGuwMM` Mobile page vs main, parity-first). Code-side
  findings fixed: **C1b** (canvas 266:2, pages.md C1b) ships — the
  post-signup "Welcome, {name} 👋" interstitial at
  `/onboarding/first-action` with the two choice cards (→ C6 capture
  entry, → C3 explore) and "Skip for now"; the router's auth redirect
  hands a FIRST sign-in off to it behind a persisted `first_action_seen`
  flag (any exit flips it; returning sign-ins go straight home). **C1**
  drops the logo mark above the wordmark (the canvas frame opens on the
  gradient wordmark alone) and both auth screens gain screen-level
  goldens. **C6** converges on the canvas capture chrome: the
  camera/countdown/QC-fail steps go FULL-BLEED (true-black ground,
  transparent over-media AppBar, shutter + on-media manual link overlaid
  — `CaptureOverlay` gains an additive `expand` axis), processing
  becomes the immersive canvas 266:8446 surface ("Measuring…" +
  "Mapping 33 landmarks from your photo — about 15 seconds." on black,
  module status hidden via an additive `showStatus`), the results screen
  gains the canvas APP-005 footer ("Measurements stay private — shared
  only when you commission a designer"), and manual entry takes the
  canvas 267:2 copy ("Enter measurements manually" / "Use a tape
  measure and enter values in cm…") plus the "Use the camera instead"
  escape hatch. **C7** restructures to the canvas/B4 vault (173:698):
  MI-11 freshness-ring header ("Measured 12 days ago" · "Up to date · N
  measurements") with Retake opening the capture-options sheet, one
  MeasurementCard per METRIC (latest value, cross-session sparkline,
  "Updated 12d ago") whose tap opens the history sheet (session rows +
  per-session delete — `MeasurementRepository.deleteSession` joins the
  contract), the inline consent/retention note with the B4 rights links
  (→ Account & data), the EmptyState-only empty frame (212:5925) and
  the MI-19 skeleton loading frame (212:5983, replacing the spinner).
  **C10** follow rows complete the NotificationRow contract: an MI-7
  Follow/Following trailing morph (one graph mutation path via
  `FollowGraphController`, re-deriving C12/C9/C3) and the row links to
  the follower's C9 profile. **C8** dispute sheet gains the canvas
  "Tell us more" placeholder. Canvas-side divergences (stray sub-AppBar
  ⋯ placeholders, back chevrons on root tabs, the missing C9 bell, the
  C14 explainer, demo measurement content off the ratified §6 seed
  story, no shutter on the C6 frames) are recorded as canvas ops in the
  audit ledger, not code changes. 8 net-new tests (355 total); goldens re-authored on
  the Linux container for every touched screen.

- Mobile profile + earnings wave (screens phase 3, the FINAL C-series
  wave — the dev flavor is now a complete C-series app over fakes;
  mobile-implementation.md §5/§6; pages.md C9, C12–C14 + B7 mobile).
  Screens: C9 own profile (the MI-11 vault-freshness ring header as THE
  C7 entry, social counts off the same follow graph the feed derives
  from, edit-profile + vault quiet pair, grid/saved icon tabs over the
  liked/saved projections — a designer side shows its published grid;
  the bell is C10's profile-tab entry, the gear opens B7), C9 designer
  public profile (B6 header, MI-7 Follow morph with the unfollow
  confirm sheet, quiet Request CTA → C5 over the newest post, published
  grid only — saved stays viewer-private) and the regular-account
  private-vault variant, C9 edit profile (display name · bio · X-10
  location), C12 followers/following (count-titled tabs over UserRows;
  every morph routes through one graph controller so C12/C9/C3
  re-derive together), B7 settings root (Google-identity block, creator
  rows off the KYC status, tri-state Appearance persisting through
  PersistenceService into MaterialApp.themeMode, canonical legal
  links) with the three canvas sub-screens — Notifications (seven
  per-event toggles, MI-18 optimistic + rollback), Privacy & consent
  (AI-processing + nearby toggles, the 30-day retention notice, the
  consent ledger), Account & data (export-everything-FIRST, Log out,
  and the quiet-danger delete ladder: the row arms a typed-confirm
  sheet where only DELETE enables the filled-destructive confirm and
  "Export everything first" is the escape hatch; deletion-pending
  disarms the row under a persistent banner) — C13 designer
  onboarding (intro/create form → payout banking form with the
  scripted Paystack states: resolving → resolved-name confirm →
  save, or failed with retry + support link; `00…` numbers fail
  deterministically and `9999999999` attaches-then-lapses, raising
  the persistent KYC banner on the designer C8 book and C14), and
  C14 earnings & payouts (EarningsSummary over the ratified ₦82,500
  available / ₦45,000 escrow canvas story, the payout-account status
  line, the tabular-figure TransactionRow ledger, non-designer/empty
  states, and a ⋯ payout request whose confirm MOVES the balance
  into a processing row — fakes mutate honestly). Data: me.json grows
  the web-Account fields, accounts.json carries the community cast +
  the web `seedFollows` graph verbatim (counts mirror the graph — the
  web P1 realism invariant, now unit-gated on mobile), earnings.json
  the C14 canvas ledger; PostRepository gains the profile/social-list
  surface, ProfileRepository becomes the account domain (me/updates/
  prefs/export/deletion), EarningsRepository the designer-monetization
  domain. Four new golden-tested `core/ui` modules (AppTabs, UserRow,
  TransactionRow, AppSwitch) and typed routes `/profile/edit`,
  `/profile/{username}` (+ C12 children), `/settings` (+3 subs),
  `/designer/onboarding` (+ `/payout` sibling).

- Mobile feed + orders wave (screens phase 3, mobile-implementation.md
  §5/§6; pages.md C2–C5, C8, C10, C11; order-lifecycle.md): the
  dev-flavor app now carries the full social + commerce journey over
  fakes. The §6 seed narrative extends with the web mock's story
  VERBATIM (`assets/seed/dev/{me,designers,posts,orders,
  notifications}.json` — same personas `kiki.adeyemi`/`amara.designs`/
  `tunde.o`/`maisonbisi`/`eniola.stitches`, same 11 posts + 33 comments
  with count==list invariants, the same ten-lifecycle-state order book
  `#APR-1005…#APR-1058` incl. the frozen child-size snapshot on
  #APR-1058 and the PR #102 event/thread cadence, the same notification
  set part-unread) plus the CC-licensed demo photography pool
  (byte-identical to `web/public/demo`, attributions carried,
  dev-flavor-scoped) — a person QA-ing web and mobile sees ONE story.
  Screens: C2 home feed (story rail with MI-8 seen-state, PostCard
  column, MI-1/2/3 like/save as REAL fake-state mutations, MI-5
  pull-to-refresh, MI-6 caught-up divider, MI-9 permalink share, loading
  skeletons/empty/error states), C3 explore (search + 3-col grid, tag
  chips, near-me proximity RE-RANKING city>state>country — never a hard
  gate, B2-parity sectioned search results with the MI-7 follow morph
  mutating the graph, per-section empties), C4 post detail (carousel
  anatomy, comments entry, pinned Request CTA → C5), C11 full-height
  comments sheet over the dimmed post (CommentRow hearts, MI-18
  composer keeping count==list), C10 notifications (day-grouped, unread
  tint+dot for the visit with read-state persisting to the repository,
  swipe-to-clear, order/post deep links, MI-16 Orders-tab badge wired
  end-to-end — opening the sheet clears it), C5 request stepper (vault
  snapshot picker off the C6/C7 sessions with the freshness ladder +
  stale warning, notes/budget/need-by, §6.3 delivery pre-fill from the
  most recent order, review, submit freezing the snapshot per
  order-lifecycle.md §1, confetti success → view order), and C8 orders
  (list with all ten state chips + contextual actions, B3 role tabs
  only when a designer side exists; detail with MI-14 event timeline,
  MI-15 PaymentBox mapping incl. escrow-held/released/refunded/
  dispute-frozen, the immutable snapshot card, MI-17 thread with the
  scripted counterparty reply, and the danger ladder: quiet-danger
  Withdraw/Decline rows arming filled-destructive dispute/decline
  sheets per the canvas). Repositories: `PostRepository`,
  `OrderRepository`, `NotificationRepository` grow their full abstract
  interfaces with seed-backed fakes applying the web store's SEMANTICS —
  engagement toggles move counts, comment counts mirror lists, the
  follow graph re-derives feed/rail, and every order mutation passes
  the order-lifecycle.md §1 transition table + §2 permissions matrix
  (illegal moves throw, never no-op); the order fake's `viewer` seam
  walks the designer surfaces (quote/decline) over the same seed.
  Typed routes `/post/{id}`, `/post/{id}/comments`, `/request/{postId}`,
  `/orders/{id}`, `/notifications` join the §5 map (post permalinks and
  order pushes deep-link in). A `clockProvider` pins screen-side
  relative-time/freshness reads for byte-stable goldens. 95 new tests
  (repository semantics incl. the transition table edge-for-edge,
  role-gated actions, snapshot freeze, scripted thread reply; widget
  states per screen at the 390px canvas width; router deep links) plus
  16 Linux-authored screen goldens (both themes). No new dependencies.
- Mobile C6 capture wave (screens phase 3 opener, mobile-implementation.md
  §10; pages.md C6/C7; capture-qc.md): the dev-flavor app completes the
  core product journey — one frontal photo + height → measurements → the
  vault — entirely over fakes. The instructional guide is rebuilt
  single-pose from the §11 salvage (kept artwork `guide1/step2/guide3/
  guide4`, tightened legacy copy; the five copy-pasted `Page1..Page5`
  classes collapse into ONE parameterized page widget; the fifth
  side-pose page stays retired — one frontal photo is the canon),
  skippable only after a first completion (persisted flag), and the ➕
  tab becomes the capture entry gesture (guide on first run, camera
  after; the designer/composer branch joins with the composer wave). The
  capture screen runs height (collected once per session, 100–230 cm
  hard gate with the cm/in display toggle) → viewfinder (Capture Kit
  `CaptureOverlay` silhouette + 3-2-1 `CountdownRing` + shutter, MI-20
  error buzz on QC fail) → `ProcessingConstellation` → `CaptureResults`
  stagger with per-measurement capture-qc.md §4 confidence (<0.7 renders
  the low chip). The camera rides an abstract `CameraService`:
  `CameraServiceLive` (new `camera` plugin, front lens) for prod's real
  viewfinder, `CameraServiceFake` (bundled sample frontal frame) so
  simulators, CI, and `main_dev` need no hardware. `MeasurementRepository`
  grows the session flow (`submitCapture` → `pending_save` →
  `saveSession`/`discardSession`, `saveManualEntry`), and the fake
  implements capture-qc.md HONESTLY: `capture_qc.dart` executes the
  §1/§2 threshold table in table order (a `QcThresholds` single config
  block), the §3 `(height × 0.93) / body_height_px` scale
  (`mediapipe_2d_v2`), and the §4 confidence formula over simulated
  per-sample pipeline metrics (`assets/seed/dev/capture_samples.json`) —
  the seeded happy path and all 11 fail codes reproduce BY RULE through
  the capture screen's dev-only QC scenario selector (rides the fake
  camera, absent over the live one), surfaced first-failure-only with
  QCHintChip codes mapped 1:1. "Save to vault" persists into the seeded
  vault store (`assets/seed/dev/vault_sessions.json` — the web mock's
  three sessions verbatim, dev-flavor-scoped assets so seeds stay out of
  prod bundles) and C7 lists it on arrival; the vault placeholder grows
  into the real C7 surface (capture/manual `CaptureOptionCard` pair +
  seeded session groups over `MeasurementCard`); MI-13 manual entry
  (four-measure v1 vocabulary, advisory out-of-range double-checks,
  never a hard block, `confidence: null`) is the fallback wired from the
  camera-permission EmptyState and the QC dead end. Typed deep-linkable
  routes `/capture`, `/capture/guide`, `/capture/manual` join `/vault`;
  Android gains the `CAMERA` permission and iOS
  `NSCameraUsageDescription` with the retention-policy copy. 63 new
  tests (the QC table rule-by-rule incl. every fail code and
  first-failure ordering over a multi-fault frame, the repository
  session flow, guide/capture/manual/vault widget states over the fake
  camera, the router matrix) plus 18 Linux-authored screen-level goldens
  (both themes). Pin-ledger addition: `camera ^0.12.0` (CameraX/
  AVFoundation via SwiftPM — no CocoaPods). Known infra note: the
  `tool/update_goldens.sh` docker image has no 3.44.7 tag upstream yet —
  goldens author via the `mobile-goldens` workflow_dispatch fallback the
  script documents.
- Mobile core/ui component wave (design phase 2, mobile-implementation.md
  §7 — one Flutter module per Figma C-series component set, golden-tested
  before any screen consumes it, the web W1 discipline): 23 new modules
  in `core/ui/` + 2 conformed. Mobile chrome — `AppTabBar` (49:384,
  icon-only tabs, gradient create FAB, MI-16 orders badge; `AppShell` now
  consumes it, replacing the Material-icon stand-in), `AppTopBar`
  (85:994, root/sub/over-media kinds, gradient wordmark), `Sheet`
  (50:296, grabber/centred title/MI-10 stepper header, `Sheet.show`
  bottom-layer presenter). The 7-set Capture Kit — `CaptureOverlay`
  (63:701, searching/aligned/countdown/qc-hint guides, pulsing
  silhouette, on-media white per the documented token exception),
  `CountdownRing` (60:590, 3/2/1), `QCHintChip` (62:634, all 11
  capture-qc.md fail codes with the canonical retake copy,
  first-failure-only), `ProcessingConstellation` (64:748, MediaPipe
  landmark pulse), `CaptureResults` (65:612, confidence-summary pill +
  MI-12 stagger), `ManualMeasureRow` (66:695, bespoke tape slider +
  cm/in flip, advisory out-of-range hint), `CaptureOptionCard` (66:721).
  Shared molecules/cards — `PostCard` (52:462, single/carousel/cta/
  skeleton, MI-1 double-tap heart), `ActionRow` (46:140, MI-2/3, filled
  Lucide heart/bookmark via inline SVG), `StoryRailItem` (46:95, MI-8
  rotating loading ring), `CaughtUpDivider` (96:1214), `StatusPill`
  (47:135, all 13 states, `-text` AA labels, MI-14 pulse), `Banner`
  (95:1220, four tones, dismiss + action slot), `MeasurementCard`
  (48:208, source chip, <0.7 low-confidence chip, bespoke sparkline),
  `PaymentBox` (90:1103, six states × two roles, itemized 10% fee line,
  MI-15 escrow explainer), `EarningsSummary` (97:1249, AA-large base
  hues), `EmptyState` (54:459, six kinds), `Skeleton` (54:464, MI-19
  shimmer), `Avatar` (42:189, ring/badge geometry per the [Decided
  2026-07-19] spec), `Button` (39:66) with the **new `quiet-danger`
  kind** (501:2, danger-ladder row rung — quiet chrome, error label).
  `GoogleAuthButton` and the salvaged `Countdown` conform to their
  inventory axes (pressed tint; ring module supersedes the m:ss text
  for C6). Constructor params mirror the Figma variant axes exactly;
  every color binds the ThemeExtensions (raw #FFFFFF only on-media);
  money/measurement text sets `FontFeature.tabularFigures()`. 56
  committed alchemist CI goldens cover every variant×state cell in
  light + dark (platform goldens disabled — images are byte-identical
  across hosts), plus behavior/a11y widget tests (icon-only controls
  carry semantics labels per the named-control canon). Pin-ledger
  addition: `lucide_icons_flutter ^3.1.15` (design.md §2 iconography).
- Mobile Google-only auth cutover (restructure step 4,
  mobile-implementation.md §9, X-1/M-3): the abstract `AuthRepository`
  grows the full contract (silent restore, `signInWithGoogle`, sign-out,
  session stream) with two implementations — `AuthRepositoryFirebase`
  (the google_sign_in 7 rewrite: `initialize(serverClientId)` →
  `authenticate()` → `GoogleAuthProvider.credential(idToken:)` →
  `signInWithCredential`; silent restore via
  `attemptLightweightAuthentication()`; tokens at rest through the
  secure-storage persistence seam, closing CV-2) and the seeded
  `AuthRepositoryFake` (instant sign-in as the web mock's `kiki.adeyemi`
  test user); C1 replaces the auth placeholder — logo, gradient wordmark,
  tagline, exactly one "Continue with Google" CTA (Google 'G' brand
  glyph, loading/notice states per flows/auth.md §4) and underlined legal
  links to the canonical Cuesoft policies; the router's auth redirect
  goes live (`refreshListenable` off the session provider — signed-out →
  `/signin`, signed-in never sees it, closing CV-7's push-only chains);
  `main_dev` boots signed in over fakes. 19 new tests cover the
  repository contract, the mocked Firebase call sequence and §4 error
  mapping, the C1 widget states, and the redirect matrix.
  `firebase_options*.dart` generation is pending `firebase login
  --reauth` (expired CLI credentials); `bootstrap(firebaseOptions:)` +
  `firebaseAuthRepositoryOverride()` are the one-diff seam for when it
  lands. Pin-ledger addition: `url_launcher ^6.3.2` (legal links).
- Mobile feature-first skeleton (restructure step 3,
  mobile-implementation.md §3–§7): `lib/src/{app,routing,core,features}`
  with the six ratified features (`auth`, `feed`, `measurements`, `orders`,
  `profile`, `earnings`), each seeded with a placeholder screen, a
  `@riverpod` ViewModel, a freezed domain model, and an abstract repository
  + `*Fake` returning empty data; a typed go_router `StatefulShellRoute`
  five-tab shell (Home · Explore · ➕ · Orders · Profile) with the auth
  redirect stubbed always-allow until the auth wave; Riverpod 3 codegen DI
  (provider overrides per environment across `main_dev` / `main_stg` /
  `main.dart`); the `core/data` seams (configured Dio `api_client`,
  secure-storage `persistence_service`); and `assets/seed/` documenting the
  §6 narrative to come.
- Design-token pipeline: `design/tokens/apparule.tokens.json` — the
  37-variable `apparule/tokens` Figma collection (17 color roles in true
  Light/Dark modes, spacing, radii, durations, z-layers), verified against
  design.md §2 — generated into `lib/src/core/theme/tokens/` by
  `tool/gen_tokens.dart`; Material 3 light + true-black dark `ThemeData`
  built from the one token set through five `ThemeExtension`s
  (color/spacing/radius/type/motion); Inter 400/600/700 bundled with its
  OFL license (never fetched at runtime).
- Android `dev`/`stg`/`prd` product flavors (`applicationIdSuffix`
  `.dev`/`.stg`, per-flavor launcher label, pubspec `default-flavor: dev`),
  paired with the three flavor entrypoints; iOS schemes/xcconfigs deferred
  to an Xcode pass.
- Mobile test suite (18 tests): a `pump_app` helper over the fake override
  set, widget tests for all eight placeholder screens, theme unit tests
  (tokens resolve; light/dark differ; true-black dark), a five-tab router
  navigation test, and countdown/persistence/api-client unit tests.
- Mobile CI lane: a `mobile · format + analyze + test` job in
  `build-and-test.yml` — Flutter pinned by `.fvmrc` via
  `subosito/flutter-action@v2`, gating `dart format`, `flutter analyze`, and
  `flutter test` — closing the audit's no-mobile-CI gap (CV-7/X-6), seeded
  with the app's first test (a boot smoke test).
- `mobile/flutter/.fvmrc` pinning Flutter 3.44.7, mirrored as hard
  `environment:` pins in `pubspec.yaml` (Dart `^3.12.0`).
- Mobile implementation contract (`docs/mobile-implementation.md`): the
  Flutter rebuild plan for `mobile/flutter` — feature-first MVVM+Repository
  over Riverpod 3, a typed go_router tab shell, a mock-first data layer
  seeded to the same designer/order narrative as the web dashboard, the
  design-token pipeline, CI quality gates, and the legacy salvage/rewrite/
  drop ledger. Docs only — restructure, design/components, and screens land
  in following stages, with API wiring last.
- Web app manifest at `/manifest.webmanifest`: product identity ("Apparule —
  Two photos. A perfect fit."), design-token colors, and the committed icon
  set — locked by the shared SEO spec's generic manifest assertion (#137).
- Self-host install snippet goes tabbed: Docker Compose and Helm (#118).
- SEO plumbing: sitemap, `robots.txt`, canonical URLs, an Open Graph card, and
  a real brand favicon in place of the placeholder (#129).

- Full web implementation: a marketing landing page and a dashboard
  application, composed from the shared component registry and running over
  a mock CRUD API (`TEST_MODE`), backed by a coherent seeded demo (designer
  profiles, orders across every lifecycle state, notifications, follows,
  comments, webcam capture sessions, and scripted Paystack payouts).
- Explore filter chips, feed/profile infinite scroll, and per-session vault
  export.
- Interactive Scalar API reference at `/docs/api`, rendered live from the
  repository's OpenAPI spec.
- Tri-state theme control (light / dark / system).
- Marketing nav: star badge, "Sign in" link, and "Try Cloud" call-to-action;
  a mobile hamburger disclosure for the canonical nav links.

- Standardized repository structure: `api/common` (Go) and `api/measure`
  (Python), plus `web`, `mobile/{flutter,android,ios}`,
  `deploy/{docker,helm,terraform}`, `docs`, and `scripts`.
- Shared community-health files from the CueLABS™ standard (SECURITY,
  CODE_OF_CONDUCT, CONTRIBUTING, CODEOWNERS, PR/issue templates) and a scoped
  Dependabot config.
- `docs/overview.md` and `docs/setup.md`.
- Production service bootstrap: `/health` + `/ready`, structured `slog` logging,
  and graceful shutdown (Go); FastAPI `lifespan` startup (measure).
- Local Docker stack: root `docker-compose.yml` (api-common:8080,
  api-measure:8081, web:3000), compose-driven `Makefile`, and `.env.example`.
- Committed `mobile/flutter/pubspec.lock` for reproducible app builds.

### Changed

- Mobile C6 capture drops the explicit shutter button — the QA-convergence
  CONTESTED item ruled for canvas+docs (pages.md C6 "silhouette overlay +
  countdown"; the canvas capture frames 173:574/266:8419 carry no control
  layer). The viewfinder now arms the 3-2-1 automatically after a short
  searching beat (`kCaptureAlignDelay`; the fake camera's stand-in for a
  live alignment signal) and capture fires on countdown completion; Retake
  re-arms it. Kept: the over-media back chevron as the cancel affordance,
  the "Enter manually instead" escape, and the ring's per-tick live
  region — plus new screen-reader announcements when the countdown arms
  ("Hold still — capturing in 3") and the capture fires ("Photo
  captured"). The unused shutter label string is gone; camera/countdown
  goldens re-authored on the Linux gate platform.
- Mobile flavors collapse to the org's two-environment model (user
  directive 2026-07-22): `dev` (fakes/TEST_MODE, applicationIdSuffix
  `.dev`) and `prod` (bare `io.cuesoft.apparule`, Firebase
  `sandbox-e306a` — CueLABS production runs on the sandbox account; the
  Doppler config name stays `stg`). `main_stg.dart` and the `stg`/`prd`
  Android flavors are gone; `main.dart` is the prod entrypoint, and a
  separate prd tier is added only when a production environment is
  ratified.
- Mobile legacy quarantine, wave 2 (mobile-implementation.md §11): all of
  `lib/src/**`, the superseded `main.dart`, and the old l10n surface
  (`app_sq.arb` + committed generated localizations) moved
  structure-preserved to `mobile/flutter/lib/legacy/` — excluded from
  analysis, codegen, CI, and builds; `countdown.dart` salvaged live to
  `src/core/ui/` per the §11 KEEP register (C6's 3-2-1 countdown).
- Mobile pubspec adopts the ratified dependency set (Riverpod 3 + codegen,
  go_router + go_router_builder, dio, freezed/json_serializable, Firebase
  packages added but not initialized, flutter_secure_storage, mocktail/
  alchemist/patrol), replacing the legacy `provider`/`sms_autofill` pair;
  documented pin deviations where the ledger's set no longer co-resolves
  (riverpod_lint is a native analyzer plugin now — custom_lint retired
  upstream; build_runner ≤2.15.1; freezed 3.2.6-dev.1 as the analyzer-12
  compatibility build; intl ^0.20.2 per the SDK's own pin).
- Mobile CI lane steps up to the full mobile-implementation.md §8 static
  gate: live-tree format scope, a codegen-fresh check (build_runner + token
  generation must produce no diff), and `flutter analyze --fatal-infos`
  over very_good_analysis + riverpod_lint. The coverage gate joins with the
  feature waves, once there is non-placeholder logic to hold a floor
  against.
- Mobile l10n re-keyed en-only (mobile-implementation.md §1): a minimal new
  `app_en.arb`; generated localizations now land in `lib/l10n/generated/`
  (gitignored, `nullable-getter: false`) instead of being committed.
- Regenerated `mobile/flutter/android/` on the Flutter 3.44.7 template
  (mobile-implementation.md §11, decisions.md M-4): AGP 9.0.1 + Gradle 9.1
  wrapper + Kotlin 2.3.20 on Java/Kotlin 17, declarative `plugins {}`
  Kotlin-DSL settings, `namespace`/Kotlin package/manifest renamed off
  `com.example.apparule` to `io.cuesoft.apparule` (matching the
  applicationId), an environment-variable release-signing stub replacing the
  debug-key release config (debug fallback documented, no secrets), the
  minSdk 24 floor and both launcher mipmap sets carried forward, and the
  dead ARCore/Sceneform native dependencies dropped.
- Replaced `mobile/flutter/.gitignore` (previously the Flutter framework
  repo's own template) with the app template plus the contract additions
  (`.fvm/`, `env/*.json`, generated l10n, golden `failures/`, Firebase
  config files); `.metadata` regenerated at the 3.44.7 revision.
- Mobile legacy quarantine, wave 1 (web-legacy pattern — nothing deleted,
  phased out when replacements land): the pre-regeneration `android/` tree
  moved to `mobile/flutter/legacy/android-agp7/`, the unused web scaffold to
  `mobile/flutter/legacy/web-scaffold/` (platform de-registered from
  `.metadata`), and eight §11-listed assets to `mobile/flutter/assets/legacy/`
  (unbundled — outside the pubspec asset list); `legacy/` trees are excluded
  from analysis and the CI gates.
- Reformatted the legacy Dart tree with `dart format` (whitespace-only) to
  seed the CI format gate.
- External links converge on `rel="noreferrer"` (which implies `noopener`) —
  the fleet legal-link idiom — across anchors and `window.open` feature
  strings (#137).
- The skip-to-content link is now the fleet's byte-identical canonical
  component: visually hidden via `sr-only` until keyboard focus reveals the
  pill; the first-Tab/Enter-to-`#main` contract is unchanged (#137).
- `/docs/api`'s Scalar reference now loads on user intent instead of shipping
  eagerly with the route, cutting settled pre-intent JS from ~1.38MB to
  ~223KB decoded (#131).
- Auth module rehomed from `controllers/auth/` to `src/auth/` for tree-shape
  parity with the sibling repos (#132).

- Home page LCP: the hero/demo image now loads with `priority` and sized WebP
  assets instead of blocking on an unoptimized full-size image (#127).
- Dead-code and env-plumbing cleanup: removed a dead hook, unused scaffold
  SVGs, and the dead `NEXT_PUBLIC_GOOGLE_CLIENT_ID` env plumbing; piped
  Playwright's `webServer` output so CI server deaths are diagnosable
  (#122, #123, #124).

- Mobile-responsive pass across every route, clean at the 390px and 768px
  breakpoints (scroll containers for wide elements, floating-layer viewport
  clamping, mobile panel and star-badge fixes).
- Cross-repo tooling parity with the other CueLABS™ repositories.

- Standard-form Helm chart (deploys api-common, api-measure, web; probes +
  recommended labels + runAsNonRoot) and cluster-agnostic terraform
  (kubeconfig-based); per-service README/.gitignore/.env.example added;
  api/measure requirements pinned to resolved versions (+ requirements-dev);
  applicationId io.cuesoft.apparule; CORS emits Vary: Origin.
- README prerequisites aligned to the actual toolchain (Go 1.26, Node.js 24,
  Python 3.12); optional `envFrom` secret hook in the Helm deployment template.
- Flutter iOS project migrated by current tooling: minimum deployment target
  iOS 13, UIScene lifecycle, Swift Package Manager integration.
- iOS bundle identifier aligned with Android: `com.example.apparule` →
  `io.cuesoft.apparule` (`.RunnerTests` suffix included).

- Moved the Python measurement service from `api/common/measurement` to
  `api/measure`.
- Aligned `.gitignore`, `.editorconfig`, and `.dockerignore` to the shared
  standard.
- Migrated `api/common` to `cmd/server` + `internal/` with singular
  purpose-based packages and `snake_case.go` files.
- Standardized web naming (kebab-case folders + modules, PascalCase components)
  and Flutter to feature-first `lib/src` with `snake_case.dart`.
- Aligned README + docs (overview, setup) to the shared CueLABS™ section
  structure; run commands use `make up` / `go run ./cmd/server`.

### Removed

- Outer `mobile/android/` and `mobile/ios/` `.gitkeep` stubs (empty
  placeholders — real platform dirs live inside `mobile/flutter/`), the iOS
  LaunchImage placeholder README, and the dead ARCore/Sceneform native
  dependencies from the Android build (§11 ledger; the pre-regeneration
  build files are preserved under `legacy/android-agp7/`).

- The legacy quarantine directory (`src/legacy/`), retired now that the
  system QA gate has passed.

- 4.9MB of unreferenced test images from git; dead Flutter files (empty
  profile screen, unimported app bar, no-op widget test); 5 unused pubspec
  dependencies; template web assets.

- GitHub Actions CI workflow, the one-off `scripts/refactor-structure.sh`, stale
  `docs/devops` planning docs, and a generated pose-detector artifact.

### Fixed

- Mobile top chrome under the display cutout (live-device defect,
  2026-07-22 — reproduced on the iPhone 17 Pro simulator AND a Galaxy
  S24 Ultra): `AppTopBar` was a fixed 56px bar that ignored
  `MediaQuery.viewPadding`, so every screen's header rendered into the
  status-bar/notch/punch-hole region on both platforms. The bar is now
  inset-aware at the chrome altitude — its surface (or the C6 over-media
  scrim) still extends behind the status bar while the 56px content row
  sits below the inset; no per-screen workarounds. The bottom tab bar
  already handled the home-indicator inset; body-`SafeArea` screens
  (C1/C1b/C3 comments/explore) were already correct.

- Mobile golden tooling: `tool/update_goldens.sh` pinned a nonexistent
  `ghcr.io/cirruslabs/flutter:3.44.7` image (upstream's newest 3.44.x
  tag is 3.44.0) — the script now runs a two-stage pin: the fixed
  `:3.44.0` base image plus an in-container git checkout of the exact
  `.fvmrc` release tag, staying in lockstep with the version CI asserts.
- Mobile C1 boot-surface overflow at ~390px (the C6-lane note): the
  GoogleAuthButton label now clamps with an ellipsis instead of
  overflowing its row; the feed/orders widget suites run at the 390px
  canvas width so any regression fails tests.
- Mobile AppTabBar badge semantics: the MI-16 count rides the tab node's
  semantics `value` ("3 new") instead of merging into its label, keeping
  the named-control contract ("Orders" stays "Orders").
- Accessibility closeout: decorative phone mocks are now truly `inert`
  (keyboard focus can no longer land in invisible mock UI), signin's legal
  links gain underlines, nav landmarks carry distinct labels, and a
  skip-to-content link fronts every route (#135).
- Contrast-token canon: AA-compliant `-text` variants for the tinted-chip
  recipe (accent/success/warn/text-2) so tinted text clears 4.5:1 in both
  themes (#128).
- Signin's legal links now point at the canonical `terms.cuesoft.io` /
  `privacy.cuesoft.io` policies instead of dead internal routes (#133).

- Figma↔code convergence pass: timezone-stable timestamps, date-popover
  anatomy, marketing chrome naming parity, MI-11 profile avatars/ring, the
  low-confidence chip's reachability, landing typography (Inter via
  `next/font`), and assorted copy-parity nits (#113, #115, #116, #119, #120,
  #121).
- Seed-photo coherence: every demo image now matches the seeded narrative
  instead of generic stock art (#125).
- Accessibility: `Sheet` dialogs restore focus to the trigger on close and
  expose `aria-modal` (#126).

- An unset theme preference now boots the design default instead of forcing
  a theme choice; the `/docs/api` header now coexists cleanly with the rest
  of the app shell.
- CueLABS™ brand mark rendering and the disabled chip remove control.
- Demo-realism and usability QA passes: coherent seed narrative, in-app
  comments, and navigation accuracy across the app.

- Flutter: form validation restored (an `if (true)` bypassed it), generated
  l10n rewired (labels rendered as empty strings), password fields start
  obscured, nested `MaterialApp`s unwrapped, persistence load awaited, Android
  INTERNET permission added, cleartext third-party logo hotlink replaced.
- Flutter: verification screens (email/SMS/account) show the signing-up user's
  contact info from local persistence instead of hardcoded sample text;
  deprecated Material color roles (`background`/`onBackground`) migrated to
  `surface`/`onSurface`.

### Security

- Pinned `postcss` (XSS advisory) and updated `js-yaml`.
