# Apparule — API Surface

> The HTTP surface as built (system-design.md §7, S-1…S-15). The web mock
> server (`web/src/app/api/mock/v1`) defined the contract and `api/common`
> implements it; the only changes are the asynchronous flows the design calls
> for (§2.2), recorded in system-design.md §16. Markers: **[Built]**,
> **[Planned]**.

## 1. Hosts and auth **[Built]**

| Host / path | Routes to | Auth |
| --- | --- | --- |
| `api.apparule.cuesoft.io/api/v1/*` | `api/common` | Firebase ID token (bearer), Google only (X-1) |
| `api.apparule.cuesoft.io/api/v1/uploads` | `api/uploads` | an upload ticket (`Upload-Ticket` header), never a user token |
| `api.apparule.cuesoft.io/webhooks/payments` | `api/common` | Paystack signature only (`X-Paystack-Signature`, HMAC-SHA512) |
| `apparule.cuesoft.io/api/v1/*` | the web's server-side proxy → the same | as above |

`common` verifies the ID token on every request (audience = the Firebase
project, `sign_in_provider == google.com`; any other provider is `403
provider_not_allowed`). First sign-in creates the account. Every resource is
account-scoped with row-level security behind it; cross-account access is
`404 not_found`, never `403`. `/health` and `/ready` exist on every service.

## 2. Endpoints **[Built]**

### 2.1 Account and consent

| Method & path | Purpose |
| --- | --- |
| `GET /me` · `PATCH /me` | the caller's account; `PATCH` takes `username` (unique, 1×/30 days → `409 name_taken` / `rename_too_soon`), `display_name`, `profile_location` (or `null`), `notification_prefs` (partial), `measurement_template` (`women` \| `men`, never cleared) |
| `GET /me/export` · `POST /me/deletion` | data export; deletion request (`409 account_has_active_orders` while money is in flight) |
| `GET /me/saved` | saved posts |
| `POST /me/devices` · `DELETE /me/devices/{token}` | FCM device tokens `{token, platform}` |
| `GET /consent` · `POST /consent` | consent records `{document: tos \| privacy, version}` |
| `GET /instance-requests` · `POST /instance-requests` | cloud instance requests (APP-002) |

### 2.2 The vault and capture

| Method & path | Purpose |
| --- | --- |
| `GET /me/sessions` | saved and unsaved results (`complete`, `pending_save`), newest first |
| `POST /me/sessions` | JSON. `{method: "manual", measurements: [{name, value_cm}]}` stores tape values at once. `{input_height_cm}` creates a capture: `201` with the session (`awaiting_upload`) and `upload {ticket, url, fields, max_files, max_bytes, expires_at}`. Consent (`403 consent_required`) and the A-10 template (`409 template_required`) are checked first; `Idempotency-Key` returns the same session with a fresh ticket |
| `POST /uploads` *(api/uploads)* | multipart `image_front` + `image_side` (or the one pose a retake ticket names) with `Upload-Ticket`; `202`. Synchronous errors name the pose: `413 file_too_large`, `415 unsupported_type`, `422 undecodable_image`; `503` with `Retry-After` while Kafka or storage is away |
| `GET /sessions/{id}` | poll: `status` `awaiting_upload` → `processing` → `pending_save` \| `failed_qc` (with `qc {code, pose, message, guidance}`) \| `failed` (`error_code: pipeline_busy`); `poses {front, side}` says which were accepted |
| `POST /sessions/{id}/poses/{front\|side}/ticket` | retake one pose of a `failed_qc` capture; the accepted pose is kept (`409 pose_accepted`) |
| `POST /sessions/{id}/save` | `pending_save` → `complete`; images move to `captures/` with a 30-day clock |
| `PATCH /sessions/{id}/measurements` | append `manual_correction` rows |
| `DELETE /sessions/{id}` | delete a session and its images ("Retake" discards unsaved results this way) |
| `POST /sessions/{id}/exports` | `{format: pdf \| csv}` → `{url}` (signed, 15 minutes) |

### 2.3 Social

| Method & path | Purpose |
| --- | --- |
| `GET /feed` | followed designers' posts, ranked; cursor = frozen rank snapshot (24 h) |
| `GET /explore?q&tags&price_band&max_turnaround_days&near_me` | filtered posts; bands `budget` < 25k, `mid` 25–100k, `premium` > 100k NGN; `near_me=1` ranks by proximity tier (city > state > country), never a gate |
| `POST /media/tickets` · `GET /media/batches/{id}` | reserve a composer upload `{count}` (designers) and poll it; items carry a preview URL |
| `POST /posts` · `GET /posts/{id}` · `DELETE /posts/{id}` | create (`media: [{media_id \| url, alt_text}]`, 1–10 images; a designer profile is needed, KYC is not); read; delete (author) |
| `POST/DELETE /posts/{id}/like` · `POST/DELETE /posts/{id}/save` | idempotent toggles |
| `GET/POST /posts/{id}/comments` | comments (≤ 500 chars) |
| `POST/DELETE /follows/{designer}` | follow a designer (idempotent) |
| `GET /profiles/{username}` · `/posts` · `/followers` · `/following` | public profiles with derived counts |
| `GET /designers?q=` · `GET /designers/suggested` | designer search and suggestions |
| `POST /reports` · `POST/DELETE /blocks/{account}` | reports (`post \| comment \| account`); silent blocks |
| `GET /moderation/queue` · `POST /moderation/reports/{id}/action` | staff: queue; `hide_post \| suspend_account \| dismiss` |

### 2.4 Orders and money

| Method & path | Purpose |
| --- | --- |
| `POST /posts/{id}/requests` | commission with `{session_id, notes, budget_cents, target_date, delivery}`; the snapshot freezes server-side; `409 post_unavailable` before the designer's KYC, `409 duplicate_request`, `429` past 10 open; `Idempotency-Key` honored |
| `GET /requests?role=customer\|designer` · `GET /requests/{id}` | party only |
| `POST /requests/{id}/quote` · `/decline` · `/status` | designer: quote (requote while quoted), decline with a reason, `in_progress` \| `shipped` |
| `POST /requests/{id}/cancel` · `/confirm-delivery` · `/dispute` | customer: withdraw or reject the quote, confirm (releases the payout), dispute (either party) |
| `POST /requests/{id}/pay` | starts the Paystack checkout: the order (still `quoted`) with `checkout {provider, reference, amount_cents, currency, email, public_key}`; it turns `paid` when the webhook's charge settles |
| `GET/POST /requests/{id}/messages` · `POST /requests/{id}/attachments/tickets` | thread (≤ 1000 chars); image attachments upload through a ticket and are referenced by `image_url` |
| `POST /moderation/requests/{id}/resolve` | staff: resolve a dispute `{outcome: delivered \| refunded}` |
| `POST /designer-profile` | enable a designer profile |
| `POST /designer/payout-account` (`/resolve` is the same) · `GET /designer/payout-account` | submit a bank account (`202`, `kyc_state: pending`), then poll until `verified` or a `reason` (`name_mismatch`, `account_invalid`) |
| `GET /designer/earnings` | balance, pending escrow, payouts and fee lines |
| `GET /notifications` · `POST /notifications/read` | activity list (90 days); mark read (`{ids}` or all) |
| `POST /webhooks/payments` | Paystack events; `200` once stored |

## 3. Conventions **[Built]**

- Base path `/api/v1`; additive changes only within a version.
- Errors: `{"error": {"code", "message", "details"}}` with the stable codes of
  engineering.md §1; QC failures carry `pose` (and `guidance`) in `details`
  or the session's `qc`.
- Lists paginate with `?cursor=` + `limit` (default 50, max 100) and answer
  `{items, next_cursor}`.
- `Idempotency-Key` (UUID) on session creation, request submission and pay:
  scope = account + endpoint; same key + same payload replays; a different
  payload is `409 idempotency_conflict`.
- Rate limits answer `429 rate_limited` with `Retry-After` (engineering.md §3).
- Money is integer minor units (kobo) with an ISO 4217 currency (NGN in v1).

## 4. Events (ECO-ANALYTICS) **[Planned]**

Landing-page events post directly from the web client to Upstat's event API
(D2); product counters (sessions created, requests) are emitted server-side by
`api/common` once D2 exists. Never measurement values.

## 5. Internal: the bus **[Built]**

Services never call each other over HTTP; their hand-offs are the events in
system-design.md §5.3, on the CueLABS shared lanes, with schemas in
`api/common/contract/`.
