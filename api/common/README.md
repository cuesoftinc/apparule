# Apparule API (`api/common`)

Go + Gin core service: auth (Google sign-in + email flow backed by Firebase)
and session JWTs. `/health` + `/ready`, slog JSON logging, graceful shutdown.

## Layout

```
cmd/server/main.go    entrypoint
internal/config       typed env config (fails fast without JWT_SECRET)
internal/auth         Firebase-backed auth service
internal/handler      HTTP handlers    internal/middleware  request-id, logging, CORS
internal/server       router + HTTP lifecycle
```

## Run

From the repo root (recommended): `cp .env.example .env && make up` → :8080.
Natively: `go run ./cmd/server` (see `.env.example` here for required vars).

## Test

```bash
go test ./...
```
