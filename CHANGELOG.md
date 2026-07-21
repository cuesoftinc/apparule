# Changelog

All notable changes to Apparule are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

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
