# Apparule — Mobile Implementation Standard

> How `mobile/flutter` gets built: the **CueLABS™ Mobile (Flutter)
> Implementation Standard** (ratified 2026-07-21, org-wide
> `oss-engineering-standards` SKILL.md §"Mobile (Flutter) implementation
> standard" — apparule is the first and only mobile product) carried by
> reference, plus the apparule-specific contract — phase plan, architecture
> tree, routing/data conventions, the C6 capture contract, and the legacy
> disposition ledger. This doc is the full detail the SKILL section points
> to; the SKILL section is the org canon and is never duplicated here beyond
> what apparule needs to build against it. Markers as in
> [design.md](design.md): **[Directive]** = user-stated direction,
> **[Proposed]** = ratifiable decision, **[Decided <date>]** = ratified.
> Companion contracts: [web-implementation.md](web-implementation.md) (the
> sibling client, same mock-first method), [flows/auth.md](flows/auth.md)
> (Google-only sign-in), [capture-qc.md](capture-qc.md) (QC thresholds +
> fail codes), [pages.md](pages.md) Part C (the C-series screen inventory),
> [design.md](design.md) §2 (tokens), [decisions.md](decisions.md) (M-series
> rulings this doc executes).

## 1. Scope & phases

Mobile is authorized for **apparule only** (2026-07-21, explicit) — no
sibling product carries a mobile app in its PRD. The build follows the same
"docs are the contract, mocks before API" method as `web/`, applied to the
existing `mobile/flutter` project rather than a greenfield tree: the legacy
app (124 tracked files, real UI, zero backend integration) is restructured
to the ratified standard before new screens land, not rewritten from
nothing.

Four phases, each closing before the next opens (mirrors the audit ledger's
**ratified migration order**):

1. **Restructure** — toolchain floor (FVM pin, Dart/AGP/Kotlin/Gradle raised,
   junk purged, no behavior change) → a mobile CI lane (analyze + test,
   closing the X-6/CV-7 gap) → the feature-first skeleton (§3), typed router
   (§5), Riverpod DI (§4), and the token theme (§7) with an en-only l10n
   re-key. Nothing user-visible changes yet.
2. **Design/components** — one `core/ui` module per Figma C-series component
   set (§7), golden-tested, before any screen consumes them — the same
   build-order discipline as `web/`'s W1 stage.
3. **Screens over seeded fakes** — every C-series screen (§5 route map)
   wired to its ViewModel and repository, backed entirely by `*Fake`
   repositories reading the seed narrative (§6). This is the bulk of the
   work and where the legacy salvage/rewrite/drop ledger (§11) executes.
4. **API last** — `*Remote` repositories implement the same interfaces the
   fakes already satisfy; `main.dart` (prod, M-7) swaps the provider
   overrides. No screen or ViewModel changes at this step by construction.

Backend integration timing follows the fleet rule: mobile's API wiring and
the backend services it calls remain separately gated — this doc covers
phases 1–3 in full and phase 4's client-side contract; the backend itself is
unauthorized independent of this doc (roadmap.md).

## 2. Toolchain

- **Flutter 3.44.7 / Dart 3.12**, pinned via **FVM** — `.fvmrc` is the single
  source of truth (CI reads it via `subosito/flutter-action@v2` with
  `cache: true`; no `v3` of that action exists yet), mirrored as a hard
  `environment: flutter:` pin in `pubspec.yaml`. Android floor **API
  24**–37; iOS **15**–26 — Firebase iOS SDK 12 (`firebase_core` 4.x, §9)
  requires iOS 15, so the deployment target is 15.0 across every build
  configuration; the generated SwiftPM package inherits the floor from
  the Xcode project on each `flutter build ios` (no hand-patching).
- **SwiftPM is the iOS dependency default** at 3.44 — CocoaPods' registry
  goes read-only 2026-12-02, so no new CocoaPods dependency is added; the
  existing iOS shell (salvaged per §11) migrates its dependency graph to
  SwiftPM as part of the restructure, not deferred to a later cleanup.
- **Flavors — exactly two (M-7)**: `dev` and `prod`. The CueLABS
  environment model has ONE real environment: the sandbox account is
  production for these projects (user directive 2026-07-22; X-6). `dev`
  carries `applicationIdSuffix ".dev"` and rides the fake repositories;
  `prod` carries the bare `io.cuesoft.apparule` id and runs on
  `sandbox-e306a`. Two `main_<flavor>` entrypoints (`main.dart` =
  `prod`, the default; `main_dev.dart` = fakes). On iOS the pair is the
  `dev`/`prod` shared schemes over `Debug/Release/Profile-<flavor>`
  build configurations (Flutter's flavor convention), each layering a
  flavor xcconfig over its mode base — iOS has no suffix mechanism, so
  `PRODUCT_BUNDLE_IDENTIFIER` is spelled per flavor
  (`io.cuesoft.apparule.dev` / bare). Flavored builds are also what
  scopes the dev-only `assets/seed/` bundle entries: a flavorless
  `xcodebuild` produces an app whose fakes run EMPTY. A third flavor
  appears only if a separate production environment is ever ratified —
  the bare id already sits on `prod`, so identity would migrate
  cleanly.
- **Env from Doppler**: secrets reach the app via
  `--dart-define-from-file=env/<flavor>.json`, generated from the
  `apparule` Doppler project (X-5) and gitignored — `dev` reads the
  `dev` config; `prod` reads the **`stg` config** (the Doppler config
  name stays `stg`; the account it configures is CueLABS production).
  No `envied` or build-time obfuscation stands in for real secret
  handling.
- **Firebase per flavor**: `flutterfire configure` run once per flavor
  against `sandbox-e306a`, producing two registrations →
  `firebase_options_dev.dart` + `firebase_options.dart` (prod)
  (committed; no secrets live in these files beyond the public API key
  model Firebase already ships with).
- Icons/splash: `flutter_launcher_icons` + `flutter_native_splash`, one
  config block per flavor. Version stamp `x.y.z+build` — humans own
  `x.y.z`, CI stamps the build number from `GITHUB_RUN_NUMBER`.

## 3. Architecture

Official Flutter **MVVM + Repository** vocabulary (docs.flutter.dev/
app-architecture; reference implementation: `flutter/samples/compass_app`):
Views bind 1:1 to ViewModels; abstract repositories are the single source of
truth for their domain and never reference each other; services are
stateless single-source wrappers; data flows one direction (UI action →
ViewModel → repository → service → back up as new state); domain models are
immutable; a `domain/` use-case layer appears inside a feature only when
genuinely earned (multiple ViewModels sharing non-trivial orchestration) —
most features skip it.

Organization is **feature-first**, not layer-first — no separate top-level
`application/` layer exists anywhere in the tree:

```
mobile/flutter/
  .fvmrc
  analysis_options.yaml
  l10n.yaml
  pubspec.yaml
  env/                        # gitignored — Doppler-generated per flavor
  assets/
    images/ icons/ fonts/
    seed/                     # §6 — dev/stg-flavor-scoped narrative JSON
  android/ ios/                # INSIDE the flutter project root (legacy had them outside — §11)
  lib/
    main.dart                  # prod entrypoint (sandbox = CueLABS production, M-7)
    main_dev.dart               # fakes wired by default
    firebase_options_dev.dart
    firebase_options.dart       # prod
    l10n/
      app_en.arb
      generated/               # gitignored, regenerates on `pub get`
    src/
      app/
        app.dart                # MaterialApp.router, ThemeExtension wiring
        bootstrap.dart           # shared bootstrap (error zones, flavor init)
        di.dart                  # Riverpod ProviderScope + per-env overrides
      routing/
        router.dart              # go_router config, StatefulShellRoute
        routes.dart               # go_router_builder typed route classes
      core/
        theme/
          tokens/                # GENERATED from Figma variables — never hand-edited
          app_theme.dart
          theme_extensions.dart  # one ThemeExtension per token group
        ui/                      # design system — one module per Figma C-series set (§7)
        data/
          api_client.dart         # single configured Dio + interceptors
          persistence_service.dart # flutter_secure_storage wrapper
        l10n/
        utils/
      features/
        auth/            {presentation,domain,data}   # C1, C1b
        feed/             {presentation,domain,data}   # C2, C3, C4, C11
        measurements/     {presentation,domain,data}   # C6, C7
        orders/            {presentation,domain,data}   # C5, C8
        profile/           {presentation,domain,data}   # C9, C10, C12
        earnings/          {presentation,domain,data}   # C13, C14
  test/                       # mirrors lib/src, + helpers/
  test_goldens/                # alchemist
  integration_test/            # patrol
```

The six top-level features (`auth`, `feed`, `measurements`, `orders`,
`profile`, `earnings`) are the ratified set (SKILL canon); the C-series →
feature mapping above is this doc's scoping decision, made the same way
`web/`'s route map resolved pages.md's shorthand (web-implementation.md
§4): notifications (C10) sit in `profile` (its entry point is the profile
tab's bell affordance, the mobile analogue of a nav-bar icon) rather than
getting a seventh top-level feature; the request stepper (C5) sits in
`orders` since it is the order-creation flow, not a feed action; comments
(C11) and explore (C3) stay in `feed` alongside the home feed and post
detail (C2/C4) since all four operate over the same post/social-graph
repository. Designer onboarding/KYC (C13) sits with earnings (C14) — one
feature for the designer-monetization surface, matching web's B8/B9
pairing.

Naming: `XViewModel` / `XScreen` / `XRepository` / `XApiService` /
`XRepositoryFake`; files `snake_case`. Each feature's `presentation/` holds
Screens + their ViewModels 1:1; `domain/` holds models (freezed) and
use-cases (only when earned); `data/` holds the repository interface, its
`_remote` and `_fake` implementations, and any feature-scoped API service.

## 4. State & dependency injection

**Riverpod 3 with codegen** — `@riverpod` annotates ViewModels;
`riverpod_generator` emits providers; `riverpod_lint` (via `custom_lint`)
enforces the conventions in CI. Widgets are `ConsumerWidget`/
`ConsumerStatefulWidget`; form/action submissions use Riverpod mutations
rather than hand-rolled loading-state fields.

DI = **provider overrides per environment** — `main_dev.dart` /
`main.dart` each build a `ProviderScope` with the repository providers
overridden to `*Fake` or `*Remote` accordingly (§6, M-7).
No second DI container (`get_it` is not introduced) — Riverpod's provider
graph is the only injection mechanism, matching the ratified rejection of
Bloc (boilerplate at this app's size) and GetX (not standards-grade). The
legacy app's `provider ^6.0.5` package (`ChangeNotifier`-based state in
`main.dart`'s static `ValueNotifier`s) is superseded outright, not
bridged — see §11.

Naming convention: `xViewModelProvider` (or `xControllerProvider` for
non-screen-scoped orchestration), generated file `x_view_model.g.dart`
committed alongside its source (§3 codegen note).

## 5. Routing

**go_router + go_router_builder**, typed routes — accepted **in maintenance
mode** (first-party, revisit only if a successor package emerges; no
alternative router is introduced meanwhile). A `StatefulShellRoute` drives
the persistent tab shell; one top-level `redirect` (via `refreshListenable`
bound to the session/auth provider) gates every route behind sign-in except
the auth screen itself, replacing the legacy's push-only Navigator 1.0
chains (CV-7 in the audit ledger — back-at-root pushing again, "Log Out"
pushing Home without clearing the stack).

Tab shell per pages.md Part C: **Home · Explore · ➕ · Orders · Profile**
(design.md §3). The centre `➕` tab is the create/request entry — for a
regular user it opens Explore→Request (C5 stepper reached from a post, not
a blank compose screen); for a designer it opens the post composer, mirroring
web's B5 creator-upsell branch. Deep links (App Links/Universal Links, per
the standard cookbook) are on by default — a post permalink
(`apparule.cuesoft.io/p/{post_id}`, web-implementation.md §4) opens the C4
post-detail screen in-app when the app is installed.

| Route | Screen | pages.md |
| --- | --- | --- |
| `/signin` | Single Google-CTA auth screen | C1 (flows/auth.md §5) |
| `/onboarding/first-action` | Post-signup interstitial | C1b |
| `/` (Home tab) | Home feed | C2 |
| `/explore` (Explore tab) | Search + grid | C3 |
| `/post/{id}` | Post detail | C4 |
| `/post/{id}/comments` | Comments sheet (full) | C11 |
| `/request/{postId}` | Request stepper | C5 |
| `/capture` (➕ tab, customer branch) | Measurement capture | C6 |
| `/vault` | Measurement vault | C7 |
| `/orders` (Orders tab) · `/orders/{id}` | Orders list + detail | C8 |
| `/profile` (Profile tab) · `/profile/{username}` | Own / other profile | C9 |
| `/profile/edit` | Edit profile (display name · bio · X-10 location) | C9 |
| `/notifications` | Notifications sheet | C10 |
| `/profile/{username}/followers` · `/following` | Followers/following | C12 |
| `/settings` · `/settings/{notifications,privacy,account}` | Settings root + the B7-mobile sub-screens (canvas 207:*) — account & data carries the export-first delete ladder | pages.md B7 |
| `/designer/onboarding` | Designer onboarding & KYC | C13 |
| `/designer/onboarding/payout` | Payout banking form (Paystack states) — a sibling under the prefix, not a child (the capture-guide precedent: re-verification entries must not stack a stale intro) | C13 |
| `/earnings` | Earnings & payouts | C14 |
| `/create` (➕ tab, designer branch) | Post composer | pages.md B5 parity |

## 6. Data layer & mock-first (TEST_MODE parity)

Every repository is **abstract**, with `*Remote` and `*Fake`
implementations satisfying the same interface — the compass-app pattern
(standards-research.md item 7). ViewModels depend only on the abstract
type; nothing above the repository boundary knows which implementation is
active. This is the mobile analogue of web's `TEST_MODE` seam
(web-implementation.md §5): the two entrypoints (`main_dev.dart`,
`main.dart`) pick the provider-override set (M-7) — both ride fakes
today; `main.dart` (prod) is where `*Remote` is introduced when API
wiring lands (§1 phase 4). No `if (kDebugMode)` branching inside
feature code.

`*Fake` repositories read seeded JSON from `assets/seed/` — the
dev-flavor asset scope keeps seed data out of prod bundles. Seed files, one per domain (mirrors the mock server's grouping,
web-implementation.md §6), tell the **same story** as the web dashboard's
seed so a person moving between the phone and the web app sees one
coherent world, not two disconnected demos:

| Seed file | Domain | Ties to (web parity) |
| --- | --- | --- |
| `assets/seed/<flavor>/me.json` | Signed-in test user: non-designer, vault populated across all three freshness states, follows several designers; account fields (email · bio · notification/privacy prefs · consent ledger) for C9/B7 | web §6 "signed-in test user" |
| `assets/seed/<flavor>/designers.json` | The Nigerian designer-persona cast, incl. `eniola.stitches` (Abuja, proximity-ranking exemplar) | web §6 designer cast |
| `assets/seed/<flavor>/accounts.json` | The community cast + the full follow edge list — C12 lists and every profile count derive from these edges (follower counts mirror the graph) | web §6 `seedFollows` verbatim |
| `assets/seed/<flavor>/earnings.json` | The designer-monetization story: `amara.designs` carries the ratified C14 canvas ledger (₦82,500 available / ₦45,000 escrow, Paystack refs) | web canvas A6/B9 demo story |
| `assets/seed/<flavor>/posts.json` | Published posts over the same CC-sourced photography pool, captions, style tags, NGN price bands | web §6 posts / design.md §8.3 asset pool |
| `assets/seed/<flavor>/vault_sessions.json` | Scan + manual measurement sessions (the source for `me.json`'s vault and for measurement snapshots frozen into orders) | web §6 vault seed / capture-qc.md |
| `assets/seed/<flavor>/orders.json` | All ten order-lifecycle states, at least one per role view, incl. an escrow-held payment and a dispute-frozen order | web §6 "all ten states" |
| `assets/seed/<flavor>/notifications.json` | Every notification kind, part unread | web §6 notifications |
| `assets/seed/<flavor>/moderation.json` | Two open reports + one actioned exemplar by `mod.sarah` | web §6 moderation queue |

`*Fake` implementations apply the same invariants the web mock store
unit-gates (comment counts match comment lists, follower counts mirror the
follow graph, snapshots are frozen copies, plausible event cadence) rather
than re-deriving them ad hoc — where practical, the fakes parse the
identical JSON shapes the web mock server already seeds from, so the two
seed sets can be regenerated from one source later without a divergent
schema.

**Data models**: `freezed` for domain models (immutable, one per
repository); `json_serializable` for API models — kept **separate** from
domain models because the Go API's JSON shapes drift from what the UI
wants (the same separation web's `models/` layer doesn't need to make,
since it talks to its own mock/API directly). `build_runner` generates
both; `.g.dart`/`.freezed.dart` are committed with a CI codegen-fresh
check (generated code is reviewed like any other diff, never silently
regenerated in CI only).

## 7. Design system

**Material 3 + one `ThemeExtension` per token group**, generated from the
apparule Figma variables collection (design.md §7) — the tokens JSON
committed in-repo is the reviewed artifact; the generated Dart
(`lib/src/core/theme/tokens/`) is never hand-edited, matching web's "no raw
hex in components" discipline (web-implementation.md §1) applied to
Flutter's theming model instead of CSS variables. Light and dark themes
build from the same token set (design.md §2's true-black dark palette);
fonts (Inter) are bundled, not fetched at runtime.

**One `core/ui` module per Figma C-series component set** — constructor
parameters mirror the Figma variant axes exactly, the same rule web's
`components/ui/*` follows for its component sets (web-implementation.md
§1). Each module is **golden-tested** (`alchemist` — `golden_toolkit` is
discontinued) across its variant matrix, both themes; a component is not
considered done until its goldens exist. MI specs that apply to mobile
(design.md §4; MI-20 haptics is mobile-only, the one MI not shared with
web) are implemented with the shared duration/easing tokens (§2 foundations
table, design.md §2) plus platform haptic feedback where named.

## 8. Quality gates

CI (mobile lane, closing CV-7 — the legacy app has zero tests and no
mobile CI lane today):

1. **Format check** — `dart format --set-exit-if-changed`.
2. **Codegen-fresh check** — `build_runner build` produces no diff against
   committed `.g.dart`/`.freezed.dart`.
3. **Static analysis** — `flutter analyze --fatal-infos` with
   `very_good_analysis` (strict casts/inference/raw-types) plus
   `custom_lint`/`riverpod_lint`.
4. **Tests with a coverage gate** — `flutter test --coverage`, gated by
   `very_good_coverage`. Unit tests (`mocktail`, not `mockito`) cover
   ViewModels, repositories, and services; widget tests cover every screen
   rendered over its `*Fake` repositories (the phase-3 deliverable, §1);
   golden tests (`alchemist`) cover every `core/ui` module (§7).
5. **E2E smoke** — `patrol` journeys covering the pages.md §8.4-equivalent
   critical paths (sign-in → feed → request → capture → vault), run
   **nightly**, not per-PR (patrol's device-farm cost profile).
6. **Build matrix** — `apk`/`ipa` build job on `main` only (X-6: PRs get
   analyze+test, not a full build matrix; `main`-merge itself never
   deploys, matching the web fleet's build+test-only gate).

## 9. Auth

Google sign-in **only**, carried from X-1/flows/auth.md unchanged in
substance — mobile has no "email stub" to delete because it never had a
production backend, but it does have a legacy screen surface implementing
the forbidden methods (§11).

- `firebase_core` + `firebase_auth` + `google_sign_in` (7.x): the sign-in
  call sequence is `GoogleSignIn.instance.initialize(serverClientId)` →
  `.authenticate()` → `GoogleAuthProvider.credential(idToken)` →
  `signInWithCredential`; silent session restore uses
  `attemptLightweightAuthentication()` on app start, replacing the legacy's
  splash-screen logic that could route a returning user back to
  `EmailVerificationPage` forever (audit ledger critical finding #4).
- `flutterfire configure` is run once per flavor against `sandbox-e306a`
  (§2) — three app registrations, three `firebase_options_<env>.dart`
  files, matching the flavor `applicationIdSuffix`/scheme.
- Session tokens live in `flutter_secure_storage` — never
  `SharedPreferences` (the legacy app's session model: plaintext PII as the
  session itself, audit ledger critical finding #3 / CV-2).
- Wrapped in an abstract `AuthRepository` with `AuthRepositoryFirebase` and
  `AuthRepositoryFake` (§6) — the fake satisfies the same interface so
  every screen downstream of sign-in works identically over seeded data
  before Firebase wiring lands.
- Screen inventory: `login_page` becomes the single auth screen (C1 —
  Google CTA + legal links, same copy as web's `/signin`); `sign_up_form`,
  `sign_up_screen`, `forgot_password`, `reset_password`, `verify_email`,
  `sms_verification`, `verify_account` are retired **by name**, per
  flows/auth.md §5 — the identical screen-removal list already ratified
  for the web auth surface, applied here to their Flutter equivalents.

## 10. Measurement capture contract (C6)

Canon: **one frontal photo + height** (api.md `POST /measure`;
capture-qc.md; flows/vault.md §1) — the legacy guide's two-pose flow (front
+ side, `guide_screen.dart`) is the divergence the audit found, not an
alternate canon to preserve.

- **Flow**: instructional guide (existing copy/art salvaged, collapsed from
  five page-classes to one pose) → camera screen with a **silhouette
  overlay** (frame the subject against a body outline) and a **3-2-1
  countdown** (the legacy `countdown.dart` `AnimatedWidget` is salvaged
  as-is per §11) → capture → upload → processing state → results.
- **Height input**: collected once per session (`user_height_cm`, api.md
  `POST /measure` form field), feeding the `scale = (user_height_cm × 0.93)
  / body_height_px` correction (capture-qc.md §3, `method: mediapipe_2d_v2`).
- **QC fail codes**: the capture screen surfaces capture-qc.md §1/§2's
  codes (`undecodable_image`, `low_resolution`, `poor_lighting`, `blurry`,
  `no_body`, `multiple_bodies`, `partial_body`, `not_frontal`,
  `camera_tilt`, `arms_position`, `too_far`) with their guidance copy,
  **first-failure-only** — one actionable retake instruction, never a
  stacked list, matching the doc's own reporting rule.
- **Results**: measurement cards stagger in with per-measurement
  `confidence` (capture-qc.md §4; values under 0.7 render a "low
  confidence — consider retaking" chip); "Save to vault" is primary,
  "Retake" is quiet; a manual-entry fallback exists for QC that never
  clears. Saved results route into the `measurements` feature's vault
  screen (C7) — the same vault a request's measurement-snapshot picker
  (C5) reads from.
- What does **not** exist yet: the SMPL/girth pipeline (roadmap Phase 3) —
  capture ships against the current 2-D MediaPipe method only; the
  response schema's `method`/`confidence`/`qc` fields are additive, so C6
  requires no rework when Phase 3 lands.

## 11. Legacy disposition

Read-only audit of the existing `mobile/flutter` (124 tracked files) found
a UI-complete prototype with **zero backend integration** (no URLs/`http`
calls anywhere in `lib/`) built against toolchain and auth patterns that
predate every ratified standard in this doc. The salvage table below is
the audit ledger's disposition, carried verbatim; the migration order (§1
phase 1–3 mapping) executes it in the stated sequence.

**KEEP** — `countdown.dart` (clean `AnimatedWidget`, reused as the C6 3-2-1
countdown); guide artwork `guide1`/`guide3`/`guide4`/`guide5` + `step2` +
logo; the l10n pipeline (`l10n.yaml` + `.arb` workflow, re-keyed en-only);
the iOS shell (patched, not replaced — freshest piece of the legacy tree:
modern `AppDelegate`/`SceneDelegate`, bundle `io.cuesoft.apparule`).

**REWRITE** — `main.dart` (the boot idea is kept; the static
`ValueNotifier`/locale plumbing and `didChangePlatformBrightness` override
are dropped for Riverpod + the theme system, §4/§7); `splash_screen.dart`
(routes on Firebase auth state, not a hardcoded destination — fixes
critical finding #4); `home_screen.dart` → becomes C1's Google CTA screen;
`guide_screen.dart` → becomes C6's single-pose flow (instructional copy
kept, five page-classes collapsed to one); the localization core (re-keyed
en-only, `sq`/Albanian dropped — see DROP); `persistence.dart` (narrowed to
a theme-preference flag only — the PII-as-session pattern is deleted, not
migrated, CV-2); `app_text_field.dart` (retokened against design.md §2);
the `android/` project (regenerated: AGP 8+/Kotlin DSL, package renamed off
`com.example.apparule` to match the `io.cuesoft.apparule` applicationId,
ARCore/Sceneform dependencies dropped, real release signing replaces the
DEBUG-key config); `README.md`/`.metadata`/`.gitignore` (the committed
`.gitignore` is presently the Flutter *framework* repo's own template, not
this project's).

**QUARANTINE → staged removal (the web legacy pattern, user directive
2026-07-21)** — superseded code is never deleted up front: it moves
structure-preserved into `mobile/flutter/lib/legacy/` (assets into
`assets/legacy/`, the old Android tree into `legacy/android-agp7/`, the
unused web scaffold into `legacy/web-scaffold/`), excluded from
`pubspec` assets, analysis, CI scope, and builds. A quarantined unit is
actually removed only when BOTH hold: its replacement has shipped and
the user gives an explicit removal go (mirroring web's route-by-route
replacement and end-of-program authorized sweeps). The quarantine set:
`welcome_screen.dart` (no-op icons, superseded by the C1 flow); all 9
files under `lib/src/features/auth/` plus `form_provider`
(password/phone/OTP auth — X-1 violation, CV-1; retired **by name** per
flows/auth.md §5, same list as §9 — quarantined at the auth cutover,
removed after C1 ships); `measurement.dart`'s menu (empty `onTap`,
CV-4); the theme trio (navy/blue "light" theme, grey "dark" theme,
asymmetric radii — rebuilt from tokens, CV-3); `my_back_button.dart`;
`number_text_input_formatter.dart`; `models/user.dart` (prefs-string
identity model, CV-2); the `sq` locale + `Language` class (dead — no
picker UI ever called `MyApp.setLocale`, CV-6); the tracked
`flutter/web/` scaffold (platform de-registered in `.metadata`); and
the assets `Blur`, `image2`, `apparule.png`, `howToMeasure`,
`takeMeasure`, `measurement.jpg`, `arrow.png`, `check.svg`. The only
true deletions: the outer `mobile/android/.gitkeep` and
`mobile/ios/.gitkeep` placeholder stubs (empty markers, not code).

**Toolchain findings folded into the restructure phase (§1)**: Dart
constraint `>=3.1.2` (Sept 2023) raised to the ratified floor; `.metadata`
(pinned at a 3.13-era `flutter create`) regenerated; `provider ^6.0.5`
removed (superseded by Riverpod 3, §4); `sms_autofill` dropped with the
auth screens it served (its Android permission model was permissionless —
no manifest change needed there, but `CAMERA` + `NSCameraUsageDescription`
are newly required for C6 and are currently **missing**); `flutter_svg`,
`shared_preferences` (narrowed use, see REWRITE), `flutter_lints`, and
`flutter_launcher_icons` carry forward current-ish, `intl` moves off its
exact `0.20.2` pin to the ratified `^0.20.3` range.

## 12. Acceptance

- [ ] Mobile CI lane green (format, codegen-fresh, analyze --fatal-infos +
      custom_lint, test --coverage gate) before any feature PR merges
- [ ] `flutter/android`/`flutter/ios` are the only platform directories;
      outer `mobile/android`, `mobile/ios` stubs and `flutter/web/` are gone
- [ ] Every repository is abstract with `*Remote` + `*Fake`; `dev`/`stg`
      entrypoints run entirely on fakes seeded from §6's narrative
- [ ] Zero password/phone/OTP auth surface remains; Google sign-in is the
      only CTA (flows/auth.md §5 parity verified)
- [ ] C6 capture produces a `mediapipe_2d_v2` result with per-measurement
      confidence and first-failure QC codes, saving into the vault (C7)
- [ ] Every `core/ui` module has goldens across its Figma variant axes,
      both themes
- [ ] API wiring (phase 4) changes zero ViewModel or screen code — only
      provider overrides move from `*Fake` to `*Remote`
