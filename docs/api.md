# Apparule — API Surface

> Current surface is verified against code; target surface implements the PRD
> and the platform requirements (prd.md §3.3). Markers: **[Current]**, **[PRD]**,
> **[Proposed]**.

## 1. Current surface **[Current]**

### api/common (Go, :8080)

| Method & path | Request | Response | Notes |
| --- | --- | --- | --- |
| `GET /health` | — | `200` static | liveness |
| `GET /ready` | — | `200` static | readiness |
| `POST /api/auth/google` | `{"id_token": "..."}` | `200 {message, project, token}` | **Stub**: does not verify `id_token`; mints JWT for the service-account email (`TODO(security-prd)`), 500 if no service identity configured |
| `POST /api/auth/email` | `{"email": "..."}` | `200 {message, email, scope}` | **Stub**: logs and returns; no link/OTP is sent |

JWT: HS256, email subject, 24h expiry (`internal/auth/jwt.go`). No endpoint
currently *requires* a token — there is nothing to protect yet.

### api/measure (Python, :8081)

| Method & path | Request | Response | Notes |
| --- | --- | --- | --- |
| `GET /health` / `GET /ready` | — | `200` | probes |
| `POST /measure` | multipart: `image` (file), `user_height_cm` (form, default 170) | `MeasurementResponse` | 422 if no body detected or image undecodable |

`MeasurementResponse`: `body_height_px`, `scale_factor`, `shoulder_width_px`,
`shoulder_width_cm`, `hip_width_px`, `hip_width_cm`.

FastAPI serves `/openapi.json` + `/docs` out of the box — the seed of APP-004.

## 2. Target surface **[Proposed]** — `/api/v1`, all on api/common unless noted

Authentication: **Firebase ID-token bearer, Google-only (X-1 hardened)** —
verified server-side (audience `sandbox-e306a`, `sign_in_provider ==
google.com`); the future `account.cuesoft.io` facade fronts the same tokens.
All routes below require auth unless marked public.
Authorization scope: every resource is workspace-scoped; membership checked per
request.

### Auth & consent

| Method & path | Purpose | Maps to |
| --- | --- | --- |
| `GET /api/v1/me` | Resolve the caller's account (idempotent upsert on first login, flows/auth.md §3); returns username + consent + designer state | X-1 |
| `PATCH /api/v1/me` | Update profile fields incl. `username` claim/rename (unique, 1×/30d) → `409 name_taken` | pages.md B6 |
| `GET /api/v1/consent` | Current user's accepted document versions | PRD §7 |
| `POST /api/v1/consent` | Record acceptance `{document, version}` | PRD §7 |

### Customers & measurement records (PLAT-001/002)

| Method & path | Purpose |
| --- | --- |
| `GET /api/v1/customers` · `POST /api/v1/customers` | list/create customers in the caller's workspace |
| `GET /api/v1/customers/{id}` · `PATCH` · `DELETE` | manage one customer (soft delete; purge per retention policy) |
| `POST /api/v1/customers/{id}/sessions` | create a measurement session: multipart image + `input_height_cm`; api/common stores the asset, calls api/measure internally, persists results |
| `GET /api/v1/customers/{id}/sessions` | measurement history for a customer |
| `GET /api/v1/sessions/{id}` | session detail incl. measurements + pipeline metadata |
| `PATCH /api/v1/sessions/{id}/measurements` | append manual corrections (`source: manual_correction`) |
| `POST /api/v1/sessions/{id}/exports` | generate `pdf`/`csv` export → signed URL (PLAT-004) |

### Cloud access (APP-002)

| Method & path | Purpose |
| --- | --- |
| `POST /api/v1/instance-requests` | request a cloud instance (consent-gated) |
| `GET /api/v1/instance-requests` | caller's requests + status |

### Events (ECO-ANALYTICS)

Landing-page events ("Demo Starts", "GitHub Clicks") post **directly from the
web client to Upstat's event API** (D2) — api/common does not proxy marketing
analytics. Product metrics (sessions created, instance requests) are emitted
server-side by api/common to the same API.

### api/measure — internal contract evolution

| Change | Why |
| --- | --- |
| `POST /measure` gains `method` selection + per-measurement `confidence`, `qc` block in the response (v2 schema, additive) | SMPL pipeline (PLAT-005) returns girths + confidence; 2-D method reports its QC verdicts |
| Service becomes internal-only in cloud topology (ClusterIP, called by api/common) | api/common is the single writer; self-hosters may still expose it directly |

## 3. Gap analysis — requirement → current → needed

| Requirement | Current state | Gap |
| --- | --- | --- |
| APP-001 GitHub gateway | README/CONTRIBUTING exist; no landing page | Landing page links (web work only) |
| APP-002 cloud access | Auth stubs; no consent, no instance model | D1 contract + consent endpoints + instance-requests + dashboard UI |
| APP-003 SMPL demo | Nothing SMPL exists | Demo media first; pipeline later (PLAT-005) |
| APP-004 API reference | FastAPI `/openapi.json` only; Go undocumented | OpenAPI spec for api/common (static YAML or swag), docs-site renderer with search |
| APP-005 privacy disclosure | None | Web page + privacy.cuesoft.io clause link (D3) |
| PLAT-001/002 records | Zero persistence | Firestore data layer (X-5), repository layer, endpoints above |
| PLAT-003 real auth | Stubs with TODOs | ID-token verification now; account.cuesoft.io when D1 lands |
| PLAT-004 export | None | Export generation + object storage |
| PLAT-005 SMPL | MediaPipe 2-D | Staged pipeline (architecture.md §5), licensing decision first |

## 4. Conventions **[Proposed]**

- Versioned base path `/api/v1`; additive changes only within a version.
- Errors: `{"error": {"code": "...", "message": "..."}}` with stable codes —
  the current ad-hoc `{"error": "text"}` shape migrates at v1.
- All list endpoints paginate (`?cursor=` + `limit`, default 50, max 100).
- Idempotency keys (`Idempotency-Key` header, UUID) on session creation,
  request submission, payments, and instance requests. Semantics **[Decided]**:
  scope = account + endpoint; dedupe window **24h**; same key + identical
  payload → replay the original response; same key + different payload →
  `409 idempotency_conflict`; keys for failed (5xx) executions are released.

---

## 5. Social commerce surface (2026-07-16 expansion) **[Proposed]**

All under `/api/v1`, workspace/account auth as §2. Deltas only:

| Group | Endpoints |
| --- | --- |
| Posts | `POST /posts` (designer) · `GET /posts/{id}` · `GET /feed` (followed + ranked) · `GET /explore?q&tags&price_band` (bands: `budget` <25k, `mid` 25–100k, `premium` >100k NGN **[Decided defaults]**) · `DELETE /posts/{id}` |
| Social graph | `POST/DELETE /follows/{designer}` · `POST/DELETE /posts/{id}/like` · `POST/DELETE /posts/{id}/save` · `POST /posts/{id}/comments` (body ≤500 chars) · `GET /posts/{id}/comments` |
| Trust & safety | `POST /reports` `{subject_kind, subject_id, reason}` · `POST/DELETE /blocks/{account}` · moderator: `GET /moderation/queue` · `POST /moderation/reports/{id}/action` `{action: hide_post\|suspend_account\|dismiss}` (A-6; semantics in data-model §6.2) |
| Requests | `POST /posts/{id}/requests` (body: vault snapshot selector, notes, budget) · `GET /requests?role=customer\|designer` · `GET /requests/{id}` · `POST /requests/{id}/quote` · `POST /requests/{id}/decline` · `POST /requests/{id}/status` (in_progress/shipped — `delivered` is customer-confirm or system auto-confirm only, order-lifecycle §2) · `POST /requests/{id}/messages` |
| Payments | `POST /requests/{id}/pay` (provider session) · `POST /webhooks/payments` (unversioned by design; **auth = provider signature only**, never bearer; unauthenticated-but-verified, engineering §2) · `POST /requests/{id}/confirm-delivery` (releases escrow) · `POST /requests/{id}/dispute` |
| Designer | `POST /designer-profile` (enable + KYC start) · `GET /designer/earnings` · `POST /designer/payout-account` |
| Notifications | `GET /notifications` · `POST /notifications/read` |

Feed/explore are the only ranked endpoints (recency + follow affinity v1; no
ML ranking until data exists). Ranked pagination **[Decided]**: cursors encode
a stable snapshot ordinal (rank computed at first page, frozen for the cursor's
24h lifetime), so pages never duplicate or skip posts within one scroll
session; new posts appear on refresh, not mid-scroll. Likes/saves/follows are idempotent PUT-style
toggles with optimistic-client semantics (design.md MI-18).
