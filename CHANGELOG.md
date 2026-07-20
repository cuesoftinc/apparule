# Changelog

All notable changes to Apparule are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
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

### Changed
- Mobile-responsive pass across every route, clean at the 390px and 768px
  breakpoints (scroll containers for wide elements, floating-layer viewport
  clamping, mobile panel and star-badge fixes).
- Cross-repo tooling parity with the other CueLABS™ repositories.

### Removed
- The legacy quarantine directory (`src/legacy/`), retired now that the
  system QA gate has passed.

### Fixed
- An unset theme preference now boots the design default instead of forcing
  a theme choice; the `/docs/api` header now coexists cleanly with the rest
  of the app shell.
- CueLABS™ brand mark rendering and the disabled chip remove control.
- Demo-realism and usability QA passes: coherent seed narrative, in-app
  comments, and navigation accuracy across the app.

### Fixed
- Flutter: form validation restored (an `if (true)` bypassed it), generated
  l10n rewired (labels rendered as empty strings), password fields start
  obscured, nested `MaterialApp`s unwrapped, persistence load awaited, Android
  INTERNET permission added, cleartext third-party logo hotlink replaced.
- Flutter: verification screens (email/SMS/account) show the signing-up user's
  contact info from local persistence instead of hardcoded sample text;
  deprecated Material color roles (`background`/`onBackground`) migrated to
  `surface`/`onSurface`.

### Changed
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

### Removed
- 4.9MB of unreferenced test images from git; dead Flutter files (empty
  profile screen, unimported app bar, no-op widget test); 5 unused pubspec
  dependencies; template web assets.

### Added
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
- GitHub Actions CI workflow, the one-off `scripts/refactor-structure.sh`, stale
  `docs/devops` planning docs, and a generated pose-detector artifact.

### Security
- Pinned `postcss` (XSS advisory) and updated `js-yaml`.
