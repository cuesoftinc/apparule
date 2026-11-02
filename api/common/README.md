# Apparule common (`api/common`)

The Go CRUD owner (docs/system-design.md §4): the whole product API, and the
only client of Postgres. It authorizes every upload and issues the ticket for
it, receives Paystack webhooks, publishes through a transactional outbox,
consumes the results of `segmentation` and `commerce`, and runs the
scheduled sweeps (Cloud Scheduler POSTs `/internal/jobs/<name>`). It makes no image or money decisions; it stores the ones
the Python services send.

## Layout

```
cmd/server/            API + Kafka consumers + outbox publisher
cmd/jobs/              one sweep by hand: captures | orders | retention | reconcile | migrate
cmd/ticketkey/         generates an upload-ticket key pair
contract/              JSON Schemas for every Kafka message (all services validate against them)
migrations/            forward-only SQL; Postgres with FORCE row-level security
internal/config        typed env config (fails fast)
internal/auth          Google OAuth code flow, session JWTs (X-1)
internal/middleware    request id, logs, CORS, auth → principal
internal/router        the /api/v1 surface (the web mock's contract)
internal/handler       thin HTTP handlers
internal/service       the CRUD rules per domain: accounts, vault, social, orders, moderation
internal/repository    every SQL statement; account-scoped or system transactions
internal/kafka         events, lanes, envelope + claim-check, producer, consumers
internal/outbox        the outbox publisher (SKIP LOCKED)
internal/sweep         the scheduled jobs (§6.7)
internal/storage       Cloud Storage (ADC) or MinIO; copy and signed URLs
internal/ticket        Ed25519 upload tickets (S-15)
internal/ratelimit     Valkey windows under `REDIS_KEY_PREFIX` (engineering.md §3)
internal/wake          wake-up calls for scaled-to-zero services
```

## How the pieces meet

- **Capture** (§6.1): `POST /api/v1/me/sessions {input_height_cm}` checks
  consent, the A-10 template, rate limits and the quota, then answers `201`
  with the session (`awaiting_upload`) and an `upload` ticket for
  `api/uploads`. `capture.uploaded` → `capture.ready` (with the template) →
  `segmentation` → `capture.measured` → `pending_save` or `failed_qc {code,
  pose}`. `POST /sessions/{id}/poses/{pose}/ticket` retakes one pose;
  `POST /sessions/{id}/save` moves the images to `captures/`.
- **Post media and attachments**: `POST /api/v1/media/tickets` and
  `POST /api/v1/requests/{id}/attachments/tickets` reserve a batch; the client
  polls `GET /api/v1/media/batches/{id}`, then names the media in
  `POST /posts` or a thread message.
- **Money** (§6.3): `POST /requests/{id}/pay` returns a Paystack `checkout`;
  `POST /webhooks/payments` verifies, stores and hands the event to
  `commerce`; `payments.outcome` moves the order and appends balanced ledger
  lines (a deferred trigger rejects anything that doesn't sum to zero).
- **Sweeps**: `POST /internal/jobs/<name>` runs one sweep (`captures`,
  `orders`, `reconcile`, `retention`; never `migrate`) and answers
  `{"job","ms"}`. The caller is Cloud Scheduler: its OIDC token must carry
  the audience `SCHEDULER_AUDIENCE` and the verified email
  `SCHEDULER_INVOKER_EMAIL`. Missing token is 401, wrong email 403, either
  variable unset 503, unknown job 404.
- **Tenancy** (S-11): handlers run as the caller (`app.account_id`), so RLS
  hides other accounts' vaults, orders and notifications; consumers, sweeps
  and staff run as system.

## Run

From the repo root (recommended): `make up`. Natively, with Postgres, Kafka,
Redis and MinIO from compose:

```bash
cp .env.example .env   # add UPLOAD_TICKET_PRIVATE_KEY from: go run ./cmd/ticketkey
go run ./cmd/server
go run ./cmd/jobs captures
```

## Test

```bash
go test ./...          # includes the RLS + flow integration suite on an embedded Postgres
go test -short ./...   # unit tests only
```
