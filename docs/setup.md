# Local Setup

## Prerequisites

- [Docker](https://www.docker.com/) & Docker Compose (recommended path)
- For native development: Go 1.26 (`api/common`), Node.js 24 (`web`,
  `api/uploads`), Python 3.12 (`api/segmentation`, `api/commerce`), Flutter
  (`mobile/flutter`)

## Configuration

Never commit secrets — provide configuration via `.env` / environment
variables. Compose reads the root `.env` (copy `.env.example`); its defaults
point every service at the local Postgres, Kafka, Redis, SeaweedFS and
Firebase auth emulator, so only a few values matter locally:

| Variable | Used by | Description |
|----------|---------|-------------|
| `UPLOAD_TICKET_PRIVATE_KEY` / `UPLOAD_TICKET_PUBLIC_KEYS` | common / uploads | The upload-ticket key pair (a local-only pair ships in `.env.example`; `go run ./cmd/ticketkey` in `api/common` makes real ones). |
| `FIREBASE_PROJECT_ID` | common, web | Firebase project; `demo-apparule` with the emulator. |
| `PAYSTACK_SECRET_KEY` / `PAYSTACK_PUBLIC_KEY` | common, commerce | Paystack test keys. Empty: checkout is off and commerce runs notify-only. |
| `FCM_PROJECT_ID`, `BREVO_*` | commerce | Optional push and email delivery. |
| `CORS_ORIGINS` | common, uploads | Browser origins allowed. |

Each service's `.env.example` lists its full set (names follow
system-design.md §10.3).

## Quick start (Docker)

```bash
cp .env.example .env
make up        # build + start the whole stack
make logs      # follow logs
make down      # stop and remove
```

- Web: http://localhost:3000 — sign in with the emulator's Google popup
- API (common): http://localhost:8080 — `/health`, `/ready`
- Uploads: http://localhost:8082 · Segmentation: :8081 · Commerce: :8083
- Firebase auth emulator: http://localhost:9099 · S3 (SeaweedFS): :8333 ·
  Kafka: localhost:9094 · Postgres: :5432

The web reaches the API through its `/api/v1` proxy, so the browser only
ever talks to :3000. `NEXT_PUBLIC_*` values are inlined into the web image at
build time, so `make up` rebuilds the web image when they change.

For the web alone on fixtures (no backend), build with
`NEXT_PUBLIC_TEST_MODE=1`: the app runs on its in-app mock server.

## Running natively (without Docker)

Run the infrastructure from compose (`docker compose up postgres kafka
kafka-init redis seaweedfs firebase-auth`), copy each service's
`.env.example` to `.env`, then:

```bash
cd api/common && go run ./cmd/server                       # :8080
cd api/common && go run ./cmd/jobs captures                # one sweep
cd api/uploads && npm ci && npm run dev                    # :8082
cd api/segmentation && pip install -r requirements-dev.txt && uvicorn app.main:app --port 8081
cd api/commerce && pip install -r requirements-dev.txt && uvicorn app.main:app --port 8083
cd web && npm install && npm run dev                       # :3000
cd mobile/flutter && flutter pub get && flutter run
```

## Tests

```bash
cd api/common && go test ./...         # includes the RLS integration suite (embedded Postgres)
cd api/uploads && npm test
cd api/segmentation && pytest
cd api/commerce && pytest
cd web && npm test
```
