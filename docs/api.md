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

Authentication: bearer token from `account.cuesoft.io` (D1) — or the hardened
local JWT until D1 lands. All routes below require auth unless marked public.
Authorization scope: every resource is workspace-scoped; membership checked per
request.

### Auth & consent

| Method & path | Purpose | Maps to |
| --- | --- | --- |
| `POST /api/v1/auth/exchange` | Exchange an `account.cuesoft.io` token for an Apparule session (until/unless the gateway validates directly) | APP-002, D1 |
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
| PLAT-001/002 records | Zero persistence | Postgres, repository layer, endpoints above |
| PLAT-003 real auth | Stubs with TODOs | ID-token verification now; account.cuesoft.io when D1 lands |
| PLAT-004 export | None | Export generation + object storage |
| PLAT-005 SMPL | MediaPipe 2-D | Staged pipeline (architecture.md §5), licensing decision first |

## 4. Conventions **[Proposed]**

- Versioned base path `/api/v1`; additive changes only within a version.
- Errors: `{"error": {"code": "...", "message": "..."}}` with stable codes —
  the current ad-hoc `{"error": "text"}` shape migrates at v1.
- All list endpoints paginate (`?cursor=` + `limit`, default 50).
- Idempotency keys accepted on session creation and instance requests
  (`Idempotency-Key` header) — measurement capture retries must not duplicate
  records on flaky mobile networks.
