# Local Setup

## Prerequisites

- [Docker](https://www.docker.com/) & Docker Compose (recommended path)
- For native development: Go 1.25+ (see `api/common/go.mod`), Node.js 20+ (`web`),
  Python 3.11+ (`api/measure`), Flutter (`mobile/flutter`)

## Configuration

Never commit secrets — provide configuration via `.env` / environment variables.
Each service ships an `.env.example` to copy from.

| Variable | Used by | Description |
|----------|---------|-------------|
| `JWT_SECRET` | `api/common` | Secret for signing session JWTs. |
| `GOOGLE_CLOUD_PROJECT` | `api/common` | GCP / Firebase project id (auth). |
| `FIREBASE_CONFIG_PATH` | `api/common` | Optional path to a mounted Firebase service-account JSON. |
| `NEXT_PUBLIC_BASE_URL` | `web` | Base URL of `api-common` as seen from the browser. |
| `NEXT_PUBLIC_GOOGLE_CLIENT_ID` | `web` | Google OAuth client id (optional locally). |

## Quick start (Docker)

```bash
cp .env.example .env
make up        # build + start api-common (:8080), api-measure (:8081), web (:3000)
make logs      # follow logs
make down      # stop and remove
```

- API (core): http://localhost:8080 — health `/health`, readiness `/ready`
- API (measure): http://localhost:8081 — health `/health`, readiness `/ready`
- Web: http://localhost:3000

`NEXT_PUBLIC_*` values are inlined into the web image at build time, so `make up`
rebuilds the web image when they change.

## Running natively (without Docker)

```bash
# Go API — listens on :8080 (override with PORT)
cd api/common && go run ./cmd/server

# Python measurement service (FastAPI) — listens on :8081 (override with PORT)
cd api/measure && pip install -r requirements.txt && uvicorn app.main:app --port 8081

# Web (dev server)
cd web && npm install && npm run dev

# Mobile
cd mobile/flutter && flutter pub get && flutter run
```
