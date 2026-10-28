# Apparule — Engineering Contracts

> Cross-cutting contracts the flow specs assume: error envelope + catalog,
> authorization matrix, rate limits, testing strategy, logging rules.
> Web implementation follows [web-implementation.md](web-implementation.md).
> Ecosystem-shared conventions originate here and are mirrored by the other
> products' engineering.md files.

## 1. Error envelope (ecosystem standard)

```json
{ "error": { "code": "snake_case_stable", "message": "human copy", "details": {} } }
```

- `code` is the API contract (clients switch on it); `message` is display
  copy and may change freely; `details` is optional structured context.
- gRPC-less product: HTTP only. Status ↔ code families:

| HTTP | Family |
| --- | --- |
| 400 | `invalid_*` (malformed input) |
| 401 | `unauthenticated`, `token_expired` |
| 403 | `consent_required`, `forbidden`, `account_disabled`, `kyc_incomplete` |
| 404 | `not_found` (never distinguishes "exists but not yours") |
| 409 | `duplicate_request`, `post_unavailable`, `name_taken` (username claim, api.md `/me`), `idempotency_conflict`, `account_has_active_orders` (deletion, flows/auth.md §4) |
| 422 | QC codes (capture-qc.md §1–2), `snapshot_invalid` |
| 429 | `rate_limited` (+ `Retry-After`) |
| 5xx | `internal`, `pipeline_busy`, `provider_unavailable` |

Full product catalog = the union of codes in flows/* and capture-qc.md; new
codes land in those docs first, never invented ad-hoc in code review.

## 2. Authorization matrix

Roles: **visitor** (unauthenticated), **user** (account), **designer**
(user + verified designer profile), **moderator** (staff), plus workspace
membership for vault-of-customers use (SME mode).

| Resource / action | visitor | user | designer | moderator |
| --- | --- | --- | --- | --- |
| Feed/explore read, post detail | ✓ (public posts) | ✓ | ✓ | ✓ |
| Like/save/comment/follow | —   | ✓ | ✓ | ✓ |
| Create post | —   | —   | ✓ (designer profile) | —   |
| Post accepts requests | —   | —   | ✓ (KYC complete, A-2 — `post_unavailable` otherwise; flows/designer.md §1) | —   |
| Own vault (read/write) | —   | ✓ self only — **no role ever reads another's vault** | ✓ self | —   |
| Workspace customers/sessions | —   | workspace members | —   | —   |
| Create request | —   | ✓ (verified, vault non-empty, consent) | ✓ as customer | —   |
| Request read/messages | —   | party only (customer or that designer) | party only | on dispute |
| Quote/decline/status | —   | —   | ✓ own requests | dispute resolution |
| Pay / confirm delivery / dispute | —   | ✓ own orders | —   | resolve |
| Earnings/payout account | —   | —   | ✓ self | —   |
| Reports/blocks | —   | ✓ | ✓ | queue + actions (block semantics: data-model §6.2 — feed filtering, interaction bans, orders survive) |

Enforcement: middleware resolves `{account, designer?, workspace?}` from the
verified token once per request; handlers declare required capability, no inline ad-hoc checks.

## 3. Rate limits (per account unless stated)

| Surface | Limit |
| --- | --- |
| `POST sessions` (capture) | 10/min, 100/day |
| Likes/saves/follows | 60/min combined (anti-spam), silent absorb over-limit for idempotent toggles |
| Comments | 10/min |
| Requests | 10 open total (flows/request.md), 20 created/day |
| Posts (designer) | 20/day |
| Auth attempts | sign-in starts limited per source and overall (Redis, in-memory fallback) |
| Media upload bandwidth | 100 MB/day/account |

429 + `Retry-After`; limits enforced in api/common (shared Redis, X-5).

## 4. Testing strategy

| Layer | Scope | Non-negotiables |
| --- | --- | --- |
| Unit (Go table-driven; pytest) | handlers, services, QC math | capture-qc golden images (1 per QC code); order state-machine transition table (every legal + illegal edge); confidence formula fixtures |
| Contract | error catalog | every documented code producible by a test |
| Integration | api/common against a real Postgres as a non-superuser (embedded, or a CI service) | RLS isolation proven cross-account; idempotency under retries; the capture flow with a per-pose retake; the commission flow from webhook to payout |
| E2E smoke (per deploy) | auth → capture → save → request → quote → pay(sandbox) → deliver | runs against sandbox before the deploy completes (release.yml gate) |
| Money invariants | platform ledger | each outcome's lines sum to zero (a deferred trigger rejects anything else); escrow returns to zero after payout |

Row-level security tests: vault, order and notification rows unreadable
cross-account by construction (the Postgres integration suite runs in CI,
not optional). Every service validates the Kafka contract's examples.

## 5. Logging & observability

- slog JSON (Go) / structlog-style (Python); every request logs one line:
  `request_id, route, status, duration_ms, account_id?` — **account id only,
  never email**.
- **Never-log list** (CI grep-gated): measurement values, capture image
  bytes/URLs with tokens, session tokens, handoff codes, payment provider payloads,
  message bodies.
- Events → the monitoring service per flow specs (counters only). Cloud Run structured
  logging picks up slog JSON natively.

## 6. Acceptance

- [ ] Error catalog test suite covers every code in flows/* + capture-qc
- [ ] Authz matrix encoded as middleware capability table + tests per row
- [x] Postgres RLS integration tests in CI
- [x] Money invariant enforced by the database and tested
- [ ] Never-log grep gate wired into build-and-test.yml

## CORS contract (ecosystem standard)

- Env: **`CORS_ORIGINS`** — comma-separated exact origins; no wildcard in
  cloud; `http://localhost:3000` default for native dev.
- Behaviour: echo the request Origin **only if allowlisted**; `Vary: Origin`;
  `Allow-Credentials: false` (bearer auth — no cookies);
  methods `GET,POST,PUT,PATCH,DELETE,OPTIONS`; headers
  `Authorization, Content-Type, Idempotency-Key, X-Org-Id`; preflight 204
  with `Access-Control-Max-Age: 600`.
- Implemented in api/common and api/uploads (`CORS_ORIGINS` — the ecosystem-standard variable name); uploads allows `POST` and the `Upload-Ticket` header only.

## Telemetry (OpenTelemetry, X-9)

- Traces: OTel SDK auto-instrumentation (HTTP server/client, gRPC, DB) +
  manual spans on domain operations; W3C traceparent propagated on every
  outbound call (incl. service-to-service).
- Metrics: OTel Meter API, each service registers its KPI instruments
  (request histograms come free; domain counters per the flow specs'
  instrumentation sections are PRODUCT events via the monitoring service's /v1/events, NOT
  OTel metrics, keep the pipelines separate).
- Logs: slog/logging → OTel bridge dual-emit (JSON stdout for Cloud Run +
  OTLP to the monitoring service). The never-log list applies to BOTH pipelines.
- Export: direct OTLP, env-gated (no endpoint ⇒ no-op); receiver = the monitoring service
  ingest (X-9). Sampling: parent-based, 10% default, errors always.
