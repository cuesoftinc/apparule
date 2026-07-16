# Apparule — Data Model

> Companion to [prd.md](prd.md) and [architecture.md](architecture.md).
> Markers: **[Current]**, **[PRD]**, **[Proposed]**.

## 1. Current state **[Current]**

There is no server-side domain persistence. The complete inventory of data at
rest today:

| Store | Data | Location |
| --- | --- | --- |
| Phone `SharedPreferences` | `name`, `email`, `phone` (from signup), `isDark` theme flag | Flutter `src/services/persistence.dart` |
| — | Measurement results | **Not stored** — `POST /measure` responses are displayed and discarded |
| Firebase project | Service-account JSON read at boot for auth stubs | Not used as a datastore |

Transient shapes in flight:

- `MeasurementResponse` (api/measure): `body_height_px`, `scale_factor`,
  `shoulder_width_px`, `shoulder_width_cm`, `hip_width_px`, `hip_width_cm`.
- JWT payload (api/common): email subject (currently the service-account email
  — stub), expiry.

## 2. Target entity model **[Proposed]** (satisfies PLAT-001/002, APP-002, §7 compliance)

```mermaid
erDiagram
    ACCOUNT ||--o{ WORKSPACE_MEMBER : "belongs to"
    WORKSPACE ||--o{ WORKSPACE_MEMBER : has
    WORKSPACE ||--o{ CUSTOMER : manages
    WORKSPACE ||--o{ INSTANCE_REQUEST : submits
    ACCOUNT ||--o{ CONSENT_RECORD : signs
    CUSTOMER ||--o{ MEASUREMENT_SESSION : "is measured in"
    MEASUREMENT_SESSION ||--o{ MEASUREMENT : produces
    MEASUREMENT_SESSION ||--o{ CAPTURE_ASSET : "captured from"
    MEASUREMENT_SESSION ||--o{ EXPORT : "exported as"

    ACCOUNT {
        uuid id PK
        string subject "account.cuesoft.io subject id"
        string email
        datetime created_at
    }
    WORKSPACE {
        uuid id PK
        string name "the SME / tailor shop"
        string plan "oss | cloud"
        datetime created_at
    }
    WORKSPACE_MEMBER {
        uuid workspace_id FK
        uuid account_id FK
        string role "owner | member"
    }
    CUSTOMER {
        uuid id PK
        uuid workspace_id FK
        string display_name
        string contact "optional email/phone"
        string notes
        datetime created_at
        datetime deleted_at "soft delete"
    }
    MEASUREMENT_SESSION {
        uuid id PK
        uuid customer_id FK
        string method "mediapipe_2d | smpl_v1 | manual"
        float input_height_cm
        string status "pending | complete | failed"
        json pipeline_meta "model version, confidence, QC flags"
        datetime created_at
    }
    MEASUREMENT {
        uuid id PK
        uuid session_id FK
        string name "shoulder_width | hip_width | chest_girth | ..."
        float value_cm
        string source "pipeline | manual_correction"
        float confidence "nullable"
    }
    CAPTURE_ASSET {
        uuid id PK
        uuid session_id FK
        string object_key "object storage reference"
        string kind "image"
        datetime retention_until "deletion deadline"
    }
    EXPORT {
        uuid id PK
        uuid session_id FK
        string format "pdf | csv"
        string object_key
        datetime created_at
    }
    INSTANCE_REQUEST {
        uuid id PK
        uuid workspace_id FK
        string status "queued | provisioning | active | rejected"
        string notes
        datetime created_at
    }
    CONSENT_RECORD {
        uuid id PK
        uuid account_id FK
        string document "tos | privacy"
        string version
        datetime accepted_at
    }
```

Modeling notes:

- **Measurement names are an open vocabulary** (a `name` string + registry
  table later, not an enum): the 2-D method produces `shoulder_width`/`hip_width`;
  SMPL adds girths; tailors add manual tape values. Each row carries its
  `source` so pipeline output and human corrections coexist per session
  (sequence 4.3 in architecture.md).
- **Sessions are immutable captures; corrections append** — an audit-friendly
  history rather than destructive edits, given production garments hang off
  these numbers.
- **`CONSENT_RECORD` is deliberately account-scoped, not workspace-scoped** —
  the PRD's ToS gate (§7) binds the person accepting.
- **`CAPTURE_ASSET.retention_until`** operationalizes the retention disclosure:
  source images are the most sensitive artifact and get the shortest default
  retention (e.g. 30 days **[Proposed]**), while derived measurements persist.

## 3. Storage mapping **[Proposed]**

| Concern | Choice | Rationale |
| --- | --- | --- |
| System of record | **Firestore** (default DB, `sandbox-e306a`) — **[Decided X-5]**, revising the earlier Postgres proposal | Firebase-native stack; real-time listeners for feed/threads/notifications; the relational entities in §2 map to collections with the workspace/customer/session hierarchy as document paths. Payments-ledger Postgres escape hatch per X-5. |
| Capture images + exports | Object storage (Firebase Storage today, S3-compatible acceptable) | Large binaries out of the DB; signed URLs for downloads. |
| Cache/queues (later) | Valkey/Redis (declared stack) | Instance-request queue, export jobs — not needed for P0. |
| Firestore | Only if `account.cuesoft.io` integration demands it | Avoid two systems of record. |

## 4. Data classification & handling **[PRD §7]**

| Class | Data | Rules |
| --- | --- | --- |
| High-sensitivity | Capture images, measurements, customer identity | Encrypted at rest; never logged (no image bytes, no measurement values in logs); shortest retention for images; deletion honours `retention_until`; export/delete rights surfaced in dashboard. |
| Sensitive | Account email, consent records | Standard PII handling; consent rows immutable. |
| Operational | Session status, pipeline metadata, event counters | No special handling; safe for logs/metrics. |

Deletion semantics: deleting a `CUSTOMER` soft-deletes then hard-purges
sessions, measurements, and capture assets on a fixed schedule (columns above);
Upstat events must only ever carry anonymous counters, never measurement data.

---

## 5. Social commerce entities (2026-07-16 expansion) **[Proposed]**

```mermaid
erDiagram
    ACCOUNT ||--o| DESIGNER_PROFILE : "may enable"
    ACCOUNT ||--o{ FOLLOW : follows
    DESIGNER_PROFILE ||--o{ POST : publishes
    POST ||--o{ POST_MEDIA : carries
    POST ||--o{ LIKE : receives
    POST ||--o{ SAVE : receives
    POST ||--o{ COMMENT : receives
    POST ||--o{ REQUEST : "commissioned via"
    ACCOUNT ||--o{ REQUEST : places
    REQUEST ||--|| MEASUREMENT_SNAPSHOT : "carries (immutable)"
    REQUEST ||--o{ ORDER_EVENT : "timeline"
    REQUEST ||--o{ THREAD_MESSAGE : discusses
    REQUEST ||--o| PAYMENT : "paid by"
    PAYMENT ||--o| PAYOUT : "released as"
    DESIGNER_PROFILE ||--o{ PAYOUT : earns

    DESIGNER_PROFILE { uuid id PK
        uuid account_id FK
        string display_name
        string bio
        string payout_account "provider ref, KYC state"
        bool verified }
    POST { uuid id PK
        uuid designer_id FK
        string caption
        json style_tags
        int base_price_cents "nullable = quote on request"
        int turnaround_days
        datetime created_at }
    REQUEST { uuid id PK
        uuid post_id FK
        uuid customer_id FK
        string status "requested|quoted|paid|in_progress|shipped|delivered|declined|disputed|cancelled"
        int quote_cents
        datetime due_at }
    MEASUREMENT_SNAPSHOT { uuid id PK
        uuid request_id FK
        json values "frozen copy of vault values + method + measured_at"
        datetime created_at }
    PAYMENT { uuid id PK
        uuid request_id FK
        string provider "paystack|stripe — to ratify"
        string state "authorized|held|released|refunded"
        int amount_cents
        int platform_fee_cents }
```

Rules: measurement snapshots are **frozen copies** (vault changes never
mutate an order); vault data is never public — a snapshot exists only inside
a request the customer initiated (privacy story for APP-005); social counters
(likes/saves) are denormalized on POST with periodic reconciliation; payments
follow escrow: `held` at pay, `released` on delivery confirmation (dispute
pauses release).
