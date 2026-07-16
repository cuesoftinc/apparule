# Apparule — Engineering Contracts

> Cross-cutting contracts the flow specs assume: error envelope + catalog,
> authorization matrix, rate limits, testing strategy, logging rules.
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
| 403 | `provider_not_allowed`, `consent_required`, `forbidden`, `account_disabled`, `kyc_incomplete` |
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
| Like/save/comment/follow | — | ✓ | ✓ | ✓ |
| Create post | — | — | ✓ (KYC complete) | — |
| Own vault (read/write) | — | ✓ self only — **no role ever reads another's vault** | ✓ self | — |
| Workspace customers/sessions | — | workspace members | — | — |
| Create request | — | ✓ (verified, vault non-empty, consent) | ✓ as customer | — |
| Request read/messages | — | party only (customer or that designer) | party only | on dispute |
| Quote/decline/status | — | — | ✓ own requests | dispute resolution |
| Pay / confirm delivery / dispute | — | ✓ own orders | — | resolve |
| Earnings/payout account | — | — | ✓ self | — |
| Reports/blocks | — | ✓ | ✓ | queue + actions (block semantics: data-model §6.2 — feed filtering, interaction bans, orders survive) |

Enforcement: middleware resolves `{account, designer?, workspace?}` from the
verified token once per request; handlers declare required capability —
no inline ad-hoc checks.

## 3. Rate limits (per account unless stated)

| Surface | Limit |
| --- | --- |
| `POST sessions` (capture) | 10/min, 100/day |
| Likes/saves/follows | 60/min combined (anti-spam), silent absorb over-limit for idempotent toggles |
| Comments | 10/min |
| Requests | 10 open total (flows/request.md), 20 created/day |
| Posts (designer) | 20/day |
| Auth attempts | Firebase-managed |
| Media upload bandwidth | 100 MB/day/account |

429 + `Retry-After`; limits enforced in api/common (shared Redis, X-5).

## 4. Testing strategy

| Layer | Scope | Non-negotiables |
| --- | --- | --- |
| Unit (Go table-driven; pytest) | handlers, services, QC math | capture-qc golden images (1 per QC code); order state-machine transition table (every legal + illegal edge); confidence formula fixtures |
| Contract | error catalog | every documented code producible by a test |
| Integration (compose) | api/common ↔ api/measure ↔ Firestore emulator | idempotency: duplicate session/request/payment under concurrent retry |
| E2E smoke (per release tag) | auth → capture → save → request → quote → pay(sandbox) → deliver | runs against sandbox before the tag deploy completes (release.yml gate) |
| Money invariants | platform ledger | property-based: Σ(payments) = Σ(payouts + fees + refunds + held) at all times |

Firestore rules tests: vault documents unreadable cross-account by
construction (emulator rule tests are part of CI, not optional).

## 5. Logging & observability

- slog JSON (Go) / structlog-style (Python); every request logs one line:
  `request_id, route, status, duration_ms, account_id?` — **account id only,
  never email**.
- **Never-log list** (CI grep-gated): measurement values, capture image
  bytes/URLs with tokens, Firebase ID tokens, payment provider payloads,
  message bodies.
- Events → Upstat per flow specs (counters only). Cloud Run structured
  logging picks up slog JSON natively.

## 6. Acceptance

- [ ] Error catalog test suite covers every code in flows/* + capture-qc
- [ ] Authz matrix encoded as middleware capability table + tests per row
- [ ] Firestore emulator rules tests in CI
- [ ] Money invariant property test present before Phase 4 merges
- [ ] Never-log grep gate wired into build-and-test.yml
