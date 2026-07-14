# Local Setup

## Quick start (Docker)

```bash
cp .env.example .env
make up        # build + start api-common (:8080), api-measure (:8081), web (:3000)
make logs      # follow logs
make down      # stop and remove
```

- API (core): http://localhost:8080 (health check: `/health`)
- API (measure): http://localhost:8081 (health check: `/health`)
- Web: http://localhost:3000

`make up` runs `docker compose up --build -d`. Configuration is read from `.env`
(see `.env.example`). `NEXT_PUBLIC_*` values are inlined into the web image at
build time, so `make up` rebuilds the web image when they change.

## Configuration

Never commit secrets — provide configuration via `.env` / environment variables:

| Variable | Used by | Description |
|----------|---------|-------------|
| `JWT_SECRET` | `api/common` | Secret for signing session JWTs. |
| `GOOGLE_CLOUD_PROJECT` | `api/common` | GCP / Firebase project id (auth). |
| `FIREBASE_CONFIG_PATH` | `api/common` | Optional path to a mounted Firebase service-account JSON for full Firebase functionality. |
| `NEXT_PUBLIC_BASE_URL` | `web` | Base URL of `api-common` as seen from the browser. |
| `NEXT_PUBLIC_GOOGLE_CLIENT_ID` | `web` | Google OAuth client id (optional locally). |

## Running services natively (without Docker)

Prerequisites: Go (see `api/common/go.mod`), Node.js 20+ (`web`), Python 3.11+
(`api/measure`), Flutter (`mobile/flutter`).

```bash
# Go API — listens on :8080 (override with PORT)
cd api/common && go run .

# Python measurement service (FastAPI) — listens on :8081 (override with PORT)
cd api/measure && pip install -r requirements.txt && uvicorn app.main:app --port 8081

# Web (dev server)
cd web && npm install && npm run dev

# Mobile
cd mobile/flutter && flutter pub get && flutter run
```
