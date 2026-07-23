# Changelog

All notable changes to Apparule are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Mobile patrol E2E smoke journeys (mobile-implementation.md §8 gate 5 —
  the standing nightly regression net, deferred since the skeleton):
  - `integration_test/smoke_journeys_test.dart` — five journeys over the
    dev flavor's fake set, asserting user-visible outcomes only (screens
    reached, data shown): cold start signed-out → C1 → fake Google
    sign-in → C1b → the seeded home feed; ➕ → chooser → the five-step
    guide → front pose → side pose → height → processing → results →
    save → the vault shows the session; explore → post detail → the
    request stepper (snapshot · delivery · review) → submit → confetti →
    order detail reads Requested; a designer session → C14's seeded
    balances (₦82,500 available / ₦45,000 escrow) → a payout request
    moves the balance into a processing row; Settings → Account & data →
    Log out → C1.
  - `patrol_finders` (3.6.0, promoted to a direct dev dependency from
    the ratified patrol 4.7.1 pin) drives the SDK's own
    `integration_test` binding — plain `flutter test integration_test
    --flavor dev` on a device, no native-automation runner.
  - `mobile-e2e` workflow — nightly + manual dispatch, never per-PR
    (§8's device-farm cost profile): Android API 34 x86_64 emulator
    (KVM-accelerated ubuntu runner) running the journey suite against
    the dev flavor.
- Mobile C15 designer post composer (M-11 — the create chooser's second
  option goes live; canvas 551:2866 / 551:4152 / 552:2):
  - The composer screen at `/create/post`: centered "New post" bar,
    media grid (110px tiles with remove dots, dashed add-zone/add-tile),
    required caption (500 cap), the snapshot-attach toggle card
    (default ON — the published post carries the vault's latest
    measurement-snapshot ref, the fit-data differentiator) and the Post
    CTA's disabled/default/loading cells; the uploading state lays
    per-tile "Uploading…" strips and null-locks every input. The
    ratified v1 contract mirrors web B5's media picker (≤10,
    JPEG/PNG/WebP, ≤10 MB) + caption; style tags / base price /
    turnaround stay web-only.
  - `MediaPickerService` seam (the `CameraService` pattern):
    `image_picker` drives the platform photo picker on prod (pin
    FLAGGED — pending the standards-research ledger); dev/CI/tests ride
    the bundled §6 sample pool, so simulators complete the full publish
    journey without a photo library. Rejections voice the web B5 copy
    (type → size → count).
  - `PostRepository.createPost` + `Post.snapshotSessionId` (web store
    parity, trimmed to v1): the §6 viewer authors the post, the fake
    simulates the upload beat, and `homeFeed` now unions the viewer's
    own posts — publish lands the post at the top of the author's feed.
    The publish routes through `EngagementActions.createPost` inside
    `runAction` (CLASS 4: a failed publish toasts and keeps the draft)
    with its DECLARED create fan-out — feed + explore family +
    own-profile grid — pinned by the two-surface contract test.
  - The M-11 chooser now routes designers' "Post an outfit" to C15;
    non-designers keep C13 become-a-designer.
- Mobile C6 two-pose capture wave (M-10/M-11 — the 2023 guide screens
  die here):
  - Canvas-first guide rebuild: ONE parameterized `GuidePage` module
    (Figma 526:33) rendering five token-bound CustomPaint illustration
    steps — intro (accent measure lines + height arrow), get ready
    (callout chips), phone setup (phone/sightline/light diagram), front
    pose (45° arm rays) and the NEW side pose (right-profile silhouette
    + turn arrow) — over the canvas-re-keyed ARB copy, including the new
    step-3 lighting bullet that teaches the `poor_lighting`/`blurry` QC
    checks up front. The legacy 2023 navy photo art
    (`guide1`/`guide3`/`guide4`/`guide5`/`step2`) is deleted; Skip
    renders on revisits only.
  - The M-10 two-pose capture flow: front "Pose 1 of 2" → side "Pose 2
    of 2" (centered over-media pose bar, M-9) → height step only when no
    height is on file → one-request submit (`image_front` +
    `image_side` + height) → processing → results. `CaptureOverlay`
    gains the Figma `pose` axis (539:2 right-profile silhouette, per-pose
    hints cleared below the pose bar); `QCHintChip` gains
    `not_side_profile` and pose-contextual `arms_position` copy (front
    "slightly away" / side "relaxed at your sides", centered regardless
    of code length). QC is per pose and first-failure-only: a retry
    re-enters the failing pose's camera only, never advances the pose
    counter, and a pose-2 failure keeps pose 1's accepted frame for the
    resubmit.
  - The honest fake, per pose: capture-qc.md's side-table deltas run in
    contract order (profile orientation at the frontality row, the
    inverted arms-relaxed rule at the arms row), the front table first;
    unknown/live side frames evaluate against side-passing defaults; the
    fake camera serves front + side sample frames (the side feed is the
    canvas's neutral dark frame) and the dev QC selector groups
    scenarios per pose so every side code is reproducible on demand. A
    per-session CSV export seam (`exportSessionCsv`, F2-9) joins the
    repository.
  - The ➕ unified create chooser (M-11 interim, canvas 548:2725): the
    centre tab opens a two-option sheet on the new `ChoiceCard` module —
    "Take measurements" (primary accent border; the guide-first-run
    logic survives behind it) and "Post an outfit" (designer-gated
    subtitle; routes to C13 become-a-designer for everyone until the
    C15 composer ships).

### Fixed

- Mobile feed/social/profile interaction defects (the audit's Lane A —
  C2/C3/C4/C9/C10/C11/C12 over the Wave-0 infrastructure):
  - Engagement converges on the `EngagementActions` façade: C2/C4
    like/save and the C11 composer all mutate through it inside
    `runAction`, so a comment posted over the feed echoes into "View
    all N comments" everywhere (D33), a failed toggle toasts at the old
    truth, and the composer clears only after a successful post — a
    failed send keeps the user's text (D34). The interim per-ViewModel
    invalidations from the live-QA wave are gone (D01 convergence), and
    every engagement body switch is value-preserving: a refresh or
    fan-out rebuild never drops rendered content to a skeleton (D28's
    CLASS 2 rule, applied to C2/C4/C11/C9/C12).
  - Follow morphs are optimistic everywhere they render: C3's designer
    rows converge on `FollowGraphController` (its fan-out re-derives
    the mounted home feed — D02), and C9 public headers, C12 rows and
    C10 follow rows read the controller's overlay
    (`overlay[username] ?? serverValue`) through `MorphSwap`, so the
    150ms morph lands the frame of the tap with rollback + toast on
    failure (D18/D19/D58/D55); `UserRow` labels come off the l10n
    catalog (D69). Pending-future morph tests pin C9 and C12.
  - The PostCard ⋯ overflow is live on C2 and C4: a post-options sheet
    with Copy link and the SOC-009 report flow (reason born unpicked,
    destructive CTA disarmed until one is chosen — CLASS 5) over the
    new `reportPost` repository seam (D23).
  - MI-5/MI-6 on the feed surfaces: C2 and C3 pull-to-refresh through
    `GradientRefreshSpinner` (72px threshold, haptic on trigger —
    MI-registry rows un-skipped, D28/D25); the C2 column is a builder
    with per-post identity keys (D61), a 4-post page window with
    prefetch at 3 cards from the end and ×2 fetch skeletons across the
    (stubbed-until-API) page seam, and the caught-up divider gated on
    the 48h freshness boundary instead of unconditional (D32).
  - MI-9 share is the native platform sheet via `share_plus` (^13.2.1,
    new dependency), degrading to the clipboard-copy idiom where no
    sheet exists (D30); the PostCard carousel rides `EdgeResistPhysics`
    so Android ends resist instead of glowing (D59).
  - C11: Reply is a real affordance — it prefills the composer with the
    author handle, arms the parent, and posted replies thread indented
    under their parent (`PostComment.parentId`, D27); the comment heart
    is the DS Lucide fill idiom shared with ActionRow (D60); the
    grabber drags the sheet to dismiss and C4 opens it on swipe-up
    (D37); heart/Close semantics own their nodes instead of merging
    into neighbours.
  - C3: long-press peeks a grid tile (scale 0.97 + dim + light haptic,
    D24); the search field grows the persisted recent-searches dropdown
    on focus (cap 5, key-value store) and an in-field clear (D36).
  - C9: edit-profile Save disarms on a blank display name and the
    ViewModel guards the API, with failures toasting instead of
    vanishing (D54); the own-profile freshness ring long-presses into
    the "Measured N days ago — retake?" tooltip so the MI-11 ladder is
    never color-only (D68).
  - Cross-fake designer-identity seam recorded: both the post and
    earnings fakes parse `designers.json`, and `enableDesigner`'s
    session-scoped divergence is documented at both sites (dissolves
    server-side with the `*Remote` wave).
  - Golden harness provides the app l10n scope (pixel-neutral); the six
    screen goldens that legitimately changed (the ⋯ overflow now
    renders on C2/C4, the C11 reply affordance) were regenerated on
    Linux per the authoring rule.

- Mobile orders/commerce interaction defects (the audit's Lane B —
  C5/C8 plus the D03/D20/D22 earnings & shell items):
  - C8 danger ladder (CLASS 5): the dispute and decline sheets are born
    DISARMED — the reason starts unpicked behind a placeholder and the
    destructive confirm arms only on a deliberate pick (D11/D12; the
    three defect-encoding unit tests rewritten as arming tests);
    confirm-delivery and withdraw/reject pass ARMED confirm sheets
    before anything irreversible moves, with the quoted state finally
    labelled "Reject quote" (D08/D09); mark-shipped gets the ship sheet
    so optional tracking is enterable (D10); the decline note the sheet
    always collected now rides `decline(id, reason, note:)` instead of
    being silently discarded (D04).
  - C8 detail: the quoted-state designer can finally requote — the
    payment box's "Edit quote" opens the quote sheet prefilled and
    `quote()` replaces the amount without a transition (D06); MI-15's
    `paying` state is driven from an in-flight ViewModel flag with a
    double-tap guard (no more unhandled paid→paid StateError) and the
    escrow explainer expands only on the in-session just-paid moment
    (D07/D64); every lifecycle action runs through `runAction`, so
    races/double-taps toast instead of failing silently (D39); the
    MI-14 timeline adopts `TimelineConnector` — declined/disputed/
    refunded/cancelled events wear the terminal-error rung, never a
    green ✓ (D41, MI-registry row un-skipped; the primitive's connector
    draw re-painted — a fractional sizer at factor 0 reported an
    infinite intrinsic height and crashed IntrinsicHeight rows); the
    released/dispute-frozen quiet CTAs are wired (payout → C14, dispute
    CTAs scroll to the new dispute section) (D42); "Declined: {reason}"
    (+ note) and the open dispute's reason/detail render to the
    counterparty (D43).
  - C8 thread: the scripted counterparty reply hides behind a 1600ms
    `TypingBubble` hold-back instead of popping in the send's own frame
    (D13, MI-17 registry row un-skipped), and sends are optimistic with
    sending/failed states and tap-to-retry — a failed send keeps the
    text on stage (D40).
  - C5 stepper: step-2 Continue gates on the six-field
    REQUIRED_DELIVERY set and the delivery form gains the recipient-name
    field, deleting the hardcoded persona fallback (D14/D15); submit
    failures surface as an error banner with the flows/request.md §1
    taxonomy — duplicate_request offers "View orders" (D38, new
    `OrderException`); soft warn banners for budget-below-base-price and
    need-by-inside-turnaround (D44); MI-20 medium haptics on submit and
    pay success (D46); step bodies slide through `StepSlide` (D62,
    registry row un-skipped); the newest vault session starts
    preselected (D63); review gains the expandable frozen-snapshot
    values section (D65).
  - C13/C14/shell: the Paystack resolve state machine supersedes instead
    of wedging — edits during an in-flight resolve start a fresh resolve
    and stale completions are dropped, so `resolving` always terminates
    (D03, Completer-driven state-machine tests); designer-onboarding
    create runs through `runAction` with the CTA disabled while either
    identity field is empty (D20); the MI-16 Orders-tab badge clears on
    TAB VISIT via the new `markOrderKindsRead` repository seam +
    `OrdersBadgeSync` shell effect — social unreads survive for C10
    (D22).

- Mobile capture/vault interaction defects (the audit's Lane C
  capture-vault cluster): the empty-vault CTA now opens the
  capture-options sheet so manual entry is reachable from an empty vault
  (D17); the vault load error renders recovery copy + Retry instead of
  raw error text (D47); per-session delete routes through `VaultActions`
  + `runAction` with a "Session deleted" toast and rollback-on-failure
  (D48/D16 — capture and manual-entry saves now ride the same façade, so
  the C9 freshness ring re-derives after every vault mutation); history
  rows gain the CSV export action with a toast (D50); the MI-13 unit
  toggle actually flips through the shared `FlipUnitToggle` (D49,
  MI-registry row un-skipped); the tape slider is assistive-technology
  operable via increase/decrease steps (D51); manual-entry rows preview
  the metric's vault history as a sparkline that animates on value
  change (D66); the C1b measurement exit `go()`es home before pushing
  capture so backing out never lands on the dismissed interstitial
  (D72); `CaptureOptionCard`'s axis renamed `photo-upload` with the
  two-photo subtitle (M-12), and the C1b/processing/height copy swept to
  the two-photo canon.

- Mobile Wave 0 interaction infrastructure (the interaction-audit CLASS
  locks — everything the fix lanes build on):
  - The MI primitive set in core/ui, each matching its design.md §4 spec
    (durations/easings from tokens, §4 exact values where the spec names
    one, reduced-motion fallbacks per §5): `MorphSwap` (MI-7 150ms),
    `FlipUnitToggle` (MI-13 200ms rotateX), `SpringBadge` (MI-16 springy
    pop — wired into the tab bar, replacing the static badge),
    `EdgeResistPhysics` (MI-4), `GradientRefreshSpinner` (MI-5, 72px
    threshold + haptic on trigger), `TypingBubble` (MI-17),
    `TimelineConnector` (MI-14 400ms draw + current pulse +
    terminal-error rung), animated `ConfettiBurst` (MI-10 ≤800ms behind
    a golden-freeze flag — the C5 success view animates to the canvas
    scatter), and `StepSlide` (MI-10 24px). Widget tests per primitive,
    goldens for the visual ones, and an MI-registry conformance harness:
    wired screens must instantiate the named primitive; lane-owned rows
    register skipped as the visible wiring ledger.
  - `AppHaptics` (MI-20 vocabulary: light/medium/error) replacing every
    direct `HapticFeedback` call, and `runAction()` — the shared
    mutation-failure seam (await → catch, `Error`s included → rollback →
    toast; input clears only on success) with l10n failure copy.
  - Mutation façades with DECLARED invalidation fan-outs, each pinned by
    a two-surface contract test (one container, keep-alive listeners on
    every declared derivation — the always-mounted-shell shape):
    `EngagementActions` (like/save/comment ⇒ homeFeed + postDetail(id) +
    profile), `FollowGraphController` rewritten optimistic-by-
    construction (synchronous follow-overlay flip, reconcile, rollback +
    rethrow; homeFeed joins the fan-out) and `VaultActions` (save/delete
    ⇒ vault + profile freshness ring). Plus the pending-future morph
    test helper (`expectMorphsWhilePending`/`expectNoSkeletons`) with a
    live demonstration over a never-resolving repository gate.
  - `failNext` throw-once seams on all six `*Fake` repositories, and
    persisted fake engagement: the viewer's like/save sets and follow
    list write through the key-value store and survive a relaunch
    (di.dart binds the real service; test helpers stay hermetic).
  - `parseAmount`/`parseAmountMinor` — one money parser (strip
    `[^0-9.]`), adopted in the C5 budget field and the C8 quote sheet,
    where the sheet's own "45,000" hint format used to permanently
    disable the CTA.
  - `notificationRoute()` — one exhaustive `NotificationKind → route`
    switch wired through C10's row tap (payout ⇒ Earnings, never
    OrderDetail), locked by an exhaustive per-kind route test.
- Web B4 two-photo upload capture (M-10 + M-12): the vault measurement
  flow is the two-file upload per the dashboard canvas frame — labeled
  Front/Side dropzones with per-pose states (empty / uploaded thumbnail
  + Replace / QC-error + hint chip), a Height (cm) row (100–230,
  prefilled from the latest capture session — never a fabricated
  default), and the "Get measurements" CTA into the processing
  constellation and results stagger. QC is per pose: the 422 names the
  failing pose, only that pose's file re-picks (an accepted pose is
  never discarded), `QCHintChip` gains the `not_side_profile` code and
  the side-pose arms copy, and the mock reports the FIRST failure by
  the capture-qc.md table order (pre-checks before pose rows). The
  options sheet and upload view carry the "Best experience: guided
  capture on the Apparule app" hint; `openapi.yaml` POST /me/sessions
  takes multipart `image_front` + `image_side` + `input_height_cm`.
- Web Create chooser (M-11 unified create semantics): the rail's Create
  pillar opens the two-option chooser — "Take measurements" (primary,
  accent border → B4 capture options via `/dashboard/vault?capture=1`)
  and "Post an outfit" (→ B5; designers see "Share a look with its fit
  data", non-designers "Become a designer to post"). NavRail items gain
  an `onSelect` action form (button + `aria-haspopup`); decorative
  marketing rails stay inert.
- Web `Button` kind `quiet-danger` — the danger-ladder row rung (quiet
  chrome + error-token label, Figma 501:2), with gallery + test
  coverage.

### Changed

- Mobile core/ui enforces the null-handler prop-contract (CLASS 3: no
  handler ⇒ no control — web hides unwired affordances, mobile was
  rendering dead ones): `PostCard` hides the ⋯ overflow (spacer keeps
  the header anatomy), `PaymentBox` renders a CTA only when its handler
  exists (the paying spinner still renders — loading is state, not an
  affordance) and `UserRow` drops the trailing morph without its
  matching handler; per-component null-callback tests enforce it.
- Mobile analyzer: `unawaited_futures` + `discarded_futures` at error
  severity (CLASS 4 — a dropped future is a dropped failure path;
  deliberate fire-and-forget sites declare `unawaited()`).
- Web manual entry carries no height: `input_height_cm` is `null` for
  `method: manual` (nullable ruling; the fabricated 168 default is
  gone), out-of-range values prompt the flows/vault.md §2 "double-check"
  advisory (non-blocking), and the `waist_girth` advisory max aligns to
  the canonical 150.
- Web AppBar sub/over-media titles center on the FULL bar width (M-9):
  an absolute, full-width, center-aligned layer over the bar — never an
  in-flow element between the slots; root's left wordmark exempt.
  Propagates to order detail, the settings sub-screens, /p/{id}, the
  marketing phone mocks and the dev gallery.
- Web B7 Account & data delete-all rides the full danger ladder:
  quiet-danger row rung → armed sheet with typed-DELETE gate, "Export
  everything first" escape hatch, and Cancel (filled destructive only
  on the armed surface).

### Fixed

- Web profile counts derive from the follow graph (user-reported live
  bug): completing become-a-designer onboarding zeroed the profile
  header's follower/following counts — `enableDesigner` created the
  DESIGNER_PROFILE with stored zero counts and the B6 header switched
  to reading them, while the graph-backed followers/following sheets
  kept the real lists. The mock store now derives
  `followers_count`/`following_count`/`posts_count` from the follow
  graph and post list at every read through the same helpers that back
  the sheets (header-vs-sheet disagreement is structurally impossible;
  the stored-tick era's missing `posts_count` decrement on post delete
  is fixed by the same move). Locked by store unit tests
  (create-designer-profile preserves counts; follow/unfollow moves both
  sides; posts_count through create+delete — parity with mobile's
  unit-gated invariant) and an e2e assertion that onboarding preserves
  the pre-onboarding counts; documented as the pages.md B6
  derived-counts rule.
- Web author links (entity-navigation rule; the web sibling of the
  user-found mobile PostCard bug): PostCard header avatar+username and
  the caption's leading username link to the designer profile
  (prop-gated — marketing mocks stay inert), PostDetailView's header
  link wraps the avatar (no dead zone), and CommentRow's avatar +
  username link to the author profile.
- Web session-restore hardening (flows/auth.md §2): `SignInGate`
  replaces a signed-in visitor to /dashboard (a signed-in user never
  sees /signin), the restore effect catches provider rejections as
  signed-out (no stranded spinner), and the provider contract
  (resolve null, never reject) is documented on
  `AuthProviderAdapter.restore()`. e2e adds the cold-start pair.
- Webcam capture flow REMOVED from web (M-12 — rejected UX:
  desk-height lens, unreachable controls): `WebcamCaptureSheet`, its
  idle tips and the webcam-upload option mode are deleted;
  `CaptureOptionCard` renames the axis to `photo-upload` ("Upload
  photos · Two photos — we measure automatically"; mobile thumbs keep
  the C7 camera title). Mobile keeps the live guided camera.

- Mobile real boot flow over fakes (user directive 2026-07-22, web
  TEST_MODE parity): cold start → native splash → session-restore gate →
  C1 when no session / straight into the tab shell when one persisted;
  sign-out (B7 Account & data) purges it back to C1.
  `AuthRepositoryFake` persists a labeled session marker through the
  same secure-storage seam the Firebase implementation uses for tokens
  at rest; `main_dev` no longer seeds a signed-in session — a first-ever
  dev launch lands on C1 and the instant fake "Continue with Google"
  survives relaunches. The restore runs behind a branded in-app
  `BootScreen` (gradient wordmark on the token `bg`; quiet spinner only
  past ~300ms) so the router mounts with a settled session — never a C1
  flash. Boot-flow suite + boot-frame goldens + notched coverage.
- Mobile brand splash + launcher icons from the design.md §2 token
  construction (white Inter-Bold "A" on the accent gradient — the web
  favicon adjudication): `tool/gen_brand_assets.mjs` (web
  `generate-brand-assets.mjs` sibling; bundled Inter, sha256 provenance)
  renders the committed `assets/brand/` sources;
  `flutter_native_splash` (first configuration) centers the tile on the
  token `bg` light/dark incl. the Android 12+ splash API
  (gradient-disc icon), and `flutter_launcher_icons` ships the adaptive
  Android icon (gradient background + white-A foreground + Android 13
  monochrome), the rounded tile for pre-26 launchers, and the
  full-bleed iOS set — replacing the 2023-era launcher icons. Both
  flavors share the mark; display names distinguish installs.

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

- Docs ratify the 2026-07-22 user rulings (contracts only — builds
  follow in their own lanes). **M-10 two-photo capture (reverses
  M-6)**: the product mechanic is two photos — front + side (right
  profile) — plus height; api.md `POST /measure` becomes `image_front`
  + `image_side` + `user_height_cm`, capture-qc.md defines per-pose QC
  (side pose: `not_side_profile` + arms-relaxed; first-failure-only per
  pose, pose-2 failures never discard pose 1), flows/vault.md §1 runs
  the two-capture sequence (QC retry never advances the pose), pages.md
  C6 and mobile-implementation.md §10 carry the two-pose flow with the
  5-step guide, and the `mediapipe_2d_v2` formula gains the two-view
  girth note ([Directive: measurement pipeline recalibration needed]).
  **M-8 canvas-first**: every shipped screen has a Figma frame —
  frameless is designed first or dropped. **M-9 centered header-bar
  titles**: true bar-width centering, chrome-scoped (design.md §8.2b
  AppBar spec; page-body titles stay left-aligned). **M-11 unified
  create semantics**: ➕/Create opens a two-option chooser on both
  platforms — "Take measurements" + "Post an outfit" (designer-gated;
  non-designers route to become-a-designer); the mobile composer (C15)
  is authorized design-first, and until it ships mobile's chooser
  offers capture + become-a-designer only. **M-12 web capture is
  upload-only**: web users upload the two photos (front + side files,
  same per-pose QC pipeline); the webcam capture flow is removed
  (rejected UX — desk-height lens, unreachable controls) and the vault
  entry hints "best experience: guided capture on the mobile app";
  mobile keeps the live guided camera; the composer create flow is
  upload/import on both platforms. **Auth posture**:
  TEST_MODE-parity fakes are the ratified state until phase 4; Firebase
  wiring stays documented but gated. **Bio scope**: designer-scoped —
  C9 edit-profile hides bio for non-designers. **Parity-audit items**:
  design.md Button `quiet-danger` + the danger-ladder row-rung rule and
  the entity-navigation rule; pages.md C1b marked mobile-only (web
  first-run = B1 empty state + freshness card); flows/auth.md §2
  platform-neutral session-restore ruling; flows/vault.md §2 advisory
  ranges canonized (waist_girth settled at 150); data-model.md
  `input_height_cm` nullable for `method: manual` (the web 168
  fabrication ends); capture-qc.md §6 records the `height_suspect` hint
  as deferred (unimplemented on both clients).

- Mobile C14 empty-ledger CTA falls back to the module-canonical
  "Discover designers" → Explore (the C8-empty precedent): its previous
  "Create a post" target was the dropped `/create` placeholder; web
  B9's CTA targets the B5 composer, which mobile ships designed-first.

- The iOS SwiftPM lockfile (`Runner.xcworkspace` `Package.resolved`) is
  committed for reproducible native resolution; the Xcode project-internal
  duplicate is gitignored (#154).

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

- The mobile legacy quarantine (M-3 staged removal, both conditions met
  2026-07-22: every replacement shipped per the QA-convergence ledger +
  the explicit user removal go): `lib/legacy/` (password/phone/OTP auth
  screens, welcome screen, legacy themes/l10n/persistence/user model),
  `assets/legacy/` (8 superseded assets), `legacy/web-scaffold/`,
  `legacy/android-agp7/`, and their analysis/codegen/CI excludes
  (incl. `build.yaml`, which existed solely for the exclusion). The
  salvaged countdown widget and promoted guide art were already live
  outside the quarantine. Also dropped: the unreferenced
  Flutter-template `ic_launcher.png` mipmaps (the manifest binds
  `@mipmap/launcher_icon`).
- The mobile `/create` placeholder route + screen (canvas-first ruling
  2026-07-22: frameless screens are designed first or dropped — no
  pages.md spec, no canvas frame). The ➕ tab keeps its five-slot canvas
  bar and remains the capture entry gesture over four shell branches;
  the designer composer arrives designed-first.

- The iOS LaunchImage placeholder README and the dead ARCore/Sceneform
  native dependencies from the Android build (§11 ledger; the
  pre-regeneration build files are preserved under `legacy/android-agp7/`).
  The outer `mobile/android/` and `mobile/ios/` `.gitkeep` placeholders
  remain — reserved for possible future native (non-Flutter) apps (user
  directive 2026-07-22); the Flutter app's platform dirs live inside
  `mobile/flutter/`.

- The legacy quarantine directory (`src/legacy/`), retired now that the
  system QA gate has passed.

- 4.9MB of unreferenced test images from git; dead Flutter files (empty
  profile screen, unimported app bar, no-op widget test); 5 unused pubspec
  dependencies; template web assets.

- GitHub Actions CI workflow, the one-off `scripts/refactor-structure.sh`, stale
  `docs/devops` planning docs, and a generated pose-detector artifact.

### Fixed

- Mobile live-QA affordance sweep (user-reported on-device, 2026-07-22):
  tapping a designer's avatar or name on a feed PostCard did nothing.
  Fixed at the component — `PostCard` gains `onProfileTap`; the header
  identity (avatar + username) is one labelled tappable and the
  caption's leading username span links too (web `PostDetailView`
  parity) — and the sweep wired every other entity reference to its
  entity screen: C2 story-rail rings → the designer's C9 profile (web
  `FeedView` parity; previously hopped to the newest post), C11
  commenter avatar/name → C9, C8 order-detail counterparty line → C9
  (web `OrderDetailView` parity), C3 designer search rows → C9 (the
  bespoke row replaced by the canonical `UserRow`, whose unfollow now
  arms the MI-7 confirm sheet instead of toggling blind). Verified
  already wired: C8 list rows, C10 notification rows, C12 UserRows, C9
  grid + counts, C3 grid tiles; C14 payout rows have no payout-detail
  surface specced. Every new tappable is a single Semantics node
  ("View {username} profile"); widget tests assert tap → route per
  affordance.
- Mobile `AppTopBar` centered-title ruling (user, 2026-07-22): sub and
  over-media titles now center on the BAR's full width — a
  measured-slot layout overlays leading/trailing at the edges and
  insets the title on both sides by the max slot width — instead of
  centering in leftover flow space, which skewed every back-only title
  right and let long titles run under the slots. The root brand bar
  keeps its left wordmark, exempt per the ruling.
- Mobile like/save to web level (user-reported live-QA): MI-20/MI-1
  light haptics on like+save set (un-actions quiet, the MI-2
  asymmetry), the MI-3 "Saved to your looks" first-save toast (once per
  install, persisted gate, View action into the profile), and
  cross-surface read-back — C2/C4 like+save invalidate the C9 profile
  grids, which previously never refreshed while the tab branch stayed
  alive.
- Mobile C9 edit profile scopes the Bio field to designer accounts
  ("follow web" ruling: web has no account-level bio edit) —
  non-designer sessions hide the field and persist their existing bio
  unchanged.

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
