# Changelog

All notable changes to Apparule are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Standardized repository structure: `api/common` (Go) and `api/measure`
  (Python), plus `web`, `mobile/{flutter,android,ios}`,
  `deploy/{docker,helm,terraform}`, `docs`, and `scripts`.
- Shared community-health files from the CueLABS standard (SECURITY,
  CODE_OF_CONDUCT, CONTRIBUTING, CODEOWNERS, PR/issue templates) and a scoped
  Dependabot config.
- `docs/overview.md` and `docs/setup.md`.
- Production service bootstrap: `/health` + `/ready`, structured `slog` logging,
  and graceful shutdown (Go); FastAPI `lifespan` startup (measure).
- Local Docker stack: root `docker-compose.yml` (api-common:8080,
  api-measure:8081, web:3000), compose-driven `Makefile`, and `.env.example`.

### Changed
- Moved the Python measurement service from `api/common/measurement` to
  `api/measure`.
- Aligned `.gitignore`, `.editorconfig`, and `.dockerignore` to the shared
  standard.
- Migrated `api/common` to `cmd/server` + `internal/` with singular
  purpose-based packages and `snake_case.go` files.
- Standardized web naming (kebab-case folders + modules, PascalCase components)
  and Flutter to feature-first `lib/src` with `snake_case.dart`.
- Aligned README + docs (overview, setup) to the shared CueLABS section
  structure; run commands use `make up` / `go run ./cmd/server`.

### Removed
- GitHub Actions CI workflow, the one-off `scripts/refactor-structure.sh`, stale
  `docs/devops` planning docs, and a generated pose-detector artifact.

### Security
- Pinned `postcss` (XSS advisory) and updated `js-yaml`.
