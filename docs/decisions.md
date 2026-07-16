# Apparule — Decision Sheet

> Every open decision gating the build, in one place. Ratify by checking a
> box (or telling the docs owner); each ratified decision flips its
> **[Proposed]** tags across the doc set to **[Decided]** and unblocks the
> listed phases. Status: ☐ open · ☑ ratified.

> **RATIFIED 2026-07-16** — all recommendations approved wholesale ("decisions
> look solid"). Where other docs still carry **[Proposed]** on these topics,
> this sheet governs; tags flip to **[Decided]** as docs are next touched.

## A-1 · Payment provider & escrow model — gates Phase 4 (Commerce)

**Question:** who moves the money, and how is "designers get paid" structured?

| Option | For | Against |
| --- | --- | --- |
| **(a) Paystack primary (NG rails) + Stripe later for international** ⭐ | Strong NG card/bank/transfer coverage; Stripe-owned (stability); subaccounts + Transfers API fit the payout flow; local currency settlement | True escrow isn't a Paystack product — we implement it as a **platform ledger**: charge to platform account at `paid`, payout via transfer at `delivered` |
| (b) Flutterwave | Broader multi-Africa coverage | Weaker fit if NG-first; same ledger requirement |
| (c) Stripe only | One provider globally | NG acquiring/settlement is the weak spot for the core market |

**Also ratify with it:** platform fee (recommend **10%** of quote, fee on
designer side, revisit at scale) · payout timing (**on delivery confirmation**,
no instant-payout v1) · refunds from platform ledger.

☑ Ratified: option (a) Paystack + platform ledger · fee 10%

## A-2 · Designer KYC — gates Phase 4

**Recommendation ⭐:** use the provider's KYC (Paystack subaccount/transfer
recipient verification: BVN/bank resolution) rather than building our own.
Gate: KYC must be complete **before** a designer's posts can accept requests.
Custom KYC only if the provider's proves insufficient.

☑ Ratified

## A-3 · SMPL licensing (R1) — gates Phase 5 for cloud

| Option | For | Against |
| --- | --- | --- |
| (a) Meshcapade/MPI commercial license now | Unblocks the real pipeline | Cost unknown; procurement before product proof |
| **(b) Launch phases 0–4 on the existing MediaPipe 2-D method; pursue a licensing quote in parallel; SMPL demo media clearly labeled "preview"** ⭐ | Nothing else waits on this; commerce works with 2-D + manual tape values; decision made with revenue data | Girth measurements arrive later |
| (c) Open-model alternatives | No license fee | Most credible body models trace back to MPI licensing anyway; research risk |

☑ Ratified: option (b) launch on 2-D, licensing quote in parallel

## A-4 · System of record — gates Phase 2 (Vault)

> **REVISED by X-5 (2026-07-16): Firestore**, not Postgres — see the
> cross-cutting section. The original recommendation below is kept for the
> audit trail.

**Recommendation ⭐: Postgres** (Aiven, already in the declared stack) for all
domain entities; object storage for capture media; Firestore not used as a
datastore (auth-only artifacts until D1). Mongo not introduced here — the
relational integrity of workspace→customer→session→snapshot is the point.

☑ Ratified

## A-5 · Cloud instance model — gates Phase 1 (APP-002)

**Recommendation ⭐:** v1 = **request queue + manual provisioning** (helm chart
per instance, ops-driven), status surfaced in dashboard. Multi-tenant SaaS is
a later re-architecture decision made with real demand data.

☑ Ratified

## A-6 · Trust & safety baseline — ships WITH Phase 3 (Social)

**Recommendation ⭐:** report post/user, block user, designer-verification
badge, and a minimal admin moderation queue (hide post, suspend account) are
**launch-blocking for the social phase** — UGC without them doesn't go public.
Automated media moderation deferred.

☑ Ratified

## A-7 · Commerce timing defaults

**Recommendation ⭐:** quote expiry **7 days** · auto-confirm delivery
**T+14 days** (2 reminders) · dispute window closes at delivery confirmation ·
order threads close 30 days after terminal state. (order-lifecycle.md)

☑ Ratified as recommended

## A-8 · Brand accent

**Recommendation ⭐:** keep the adapted Instagram gradient (#E1306C→#F77737,
now in `apparule/tokens`) as the working accent; schedule a proper brand pass
before public launch. Alternative: commission the brand pass first.

☑ Ratified

## Cross-cutting (shared with expendit/upstat)

- **X-1 account.cuesoft.io / identity (RATIFIED)**: interim + sandbox identity
  is **Firebase Authentication on GCP project `sandbox-e306a`** ("sandbox") —
  Google sign-in + email flows come from Firebase; services verify Firebase ID
  tokens (OIDC-compatible). `account.cuesoft.io` **is not built yet** — each app replicates the
  sign-in screens **in-app** (own UI per its design system,
  Firebase Auth underneath — Google sign-in only; the email/password wording
  that stood here pre-hardening is void). The
  central facade fronts the same Firebase project later without contract
  changes; in-app screens then become optional, not obsolete. **HARDENED
  2026-07-16: Google sign-in is the ONLY method — no username/password
  signup or login, product-wide.** Email/Password provider disabled at
  the Firebase project; backends reject non-Google-provider tokens
  (`provider_not_allowed`); UI ships exactly one auth CTA. Full contract:
  [flows/auth.md](flows/auth.md). Environment/secrets live in **Doppler**
  (`cueprise/cuesoft_stg`; see also the `cuesoft-iac` project) — CLI token
  currently expired (`doppler login` to refresh); config names to be mirrored
  into docs once readable. ☑
- **X-2 Docs platform**: GitBook org with **one space per product**,
  Git-synced from each repo's `docs/`; API refs rendered by **Scalar** from
  OpenAPI, embedded in each docs space. ☑
- **X-3 Cloud deployment target (RATIFIED, directive)**: all backend
  services run on **Google Cloud Run** (per-service containers — the same
  `cuesoft/<repo>-<service>` images), following the cueprise pattern
  (IaC precedent in `cuesoft-iac`); frontends deploy to **Firebase App
  Hosting**. Helm + terraform in `deploy/` remain the **self-host** path —
  cloud and self-host share images, not manifests. ☑
- **X-4 AI platform (RATIFIED, directive 2026-07-16)**: AI features use
  **Vertex AI** (Gemini via `{region}-aiplatform.googleapis.com`, ADC from the
  service account — the `cuesoft-iac/functions/cueprise-gemini-proxy` pattern;
  reference model `gemini-2.5-flash-lite`, region `us-central1`). No
  consumer-API keys to third-party AI vendors in cloud deployments — data
  stays inside GCP, which strengthens every privacy disclosure. Self-host
  fallback: bring-your-own Gemini/Groq key via env (existing code path). ☑
- **X-5 Data plane (RATIFIED 2026-07-16, per-product DB decided by delegation)**:
  **Firestore** (default database, project `sandbox-e306a`) as the system of
  record — **revises A-4 (Postgres)**: Firebase-native stack + real-time
  listeners/offline sync are decisive for a social mobile app (feed, order
  threads, notifications without websocket infra). Escape hatch: the payments
  ledger alone may carve out to Aiven Postgres if Firestore transaction
  guarantees ever pinch. Media stays on Firebase Storage.
  **Shared Redis**: the sandbox **Aiven Redis** instance, tenancy by
  **`REDIS_DB` index** (the irealty pattern: discrete `REDIS_HOST/PORT/
  USERNAME/PASSWORD/TLS/DB` vars; e.g. irealty prd=0, stg/dev=1) — indices
  per product/config assigned in Doppler by the owner. **Doppler is the env
  source of truth**: project `apparule` with `dev / dev_personal / stg / prd`
  configs (already created). **Object storage**: the **default Cloud Storage bucket** in
  `sandbox-e306a` (per-product prefixes `apparule/<env>/…`) for capture
  media, exports, and artifacts. Self-host compose keeps its bundled
  stores. ☑
- **X-6 Environments & deploy gating (RATIFIED 2026-07-16, deliberate
  deviation from the cueprise norm)**: `stg` = **sandbox** and is the ONLY
  environment — no production deployment exists for these products. Secrets
  live in Doppler `<project>/stg`. Because these repos are **open source**,
  merge-to-main must NOT deploy: main-merge runs build+test only. **Deploys
  happen exclusively on tag creation (`v*`)**, treated as production-grade:
  a GitHub tag ruleset restricts `v*` creation to owner-level access, and the
  deploy workflow additionally runs in a protected GitHub environment. ☑
- **X-7 Transactional email (RATIFIED, directive 2026-07-16)**: **Brevo REST
  API** for all product email (alert emails, money-event receipts, purge
  confirmations…) — the irealty pattern: `BREVO_API_KEY`, `BREVO_FROM_EMAIL`,
  `BREVO_FROM_NAME` in Doppler. **No SMTP anywhere** — existing SMTP/gomail
  plumbing retires when next touched. Revises U-4's Resend pick where it
  applied. ☑
- **X-8 Protocol standard (RATIFIED 2026-07-16)**: ecosystem APIs are
  **HTTP/JSON**. gRPC exists ONLY where upstat needs it: **OTLP/gRPC ingest**
  (OTel industry standard, OBS-001), internal s2s (observability↔common),
  and the existing monitor control plane until monitors-v2. Cloud Run runs
  gRPC fine with end-to-end HTTP/2 (h2c) — already how api/common works.
  **Browser gRPC-Web + Envoy is a sunset path**: no new surface uses it
  (U-5); at monitors-v2 (OBS-006) the dashboard goes fully HTTP and Envoy
  retires from the cloud topology. apparule/expendit never adopt gRPC. ☑
- **X-9 Telemetry standard (RATIFIED, directive 2026-07-16)**: **OpenTelemetry
  everywhere** — traces, custom metrics, and logs from every service via OTel
  SDKs (Go: otel-go + slog bridge; Python: opentelemetry-python + logging
  handler; Next: @opentelemetry/sdk-node), W3C `traceparent` propagation
  across HTTP and gRPC. **Export: direct OTLP from the SDK in v1** (batch
  processors; collector sidecar on Cloud Run is the documented upgrade path
  for tail sampling/fan-out). **Receiver: upstat's OTLP ingest gateway**
  (OBS-001; gRPC 4317 + HTTP 4318, `Upstat-Ingest-Key` via
  OTEL_EXPORTER_OTLP_HEADERS) — sibling products are its first-party
  customers. **Sibling exporters default to OTLP/HTTP (4318)** — apparule
  and expendit remain 100% HTTP in practice; only upstat hosts gRPC (X-8). Until OBS-001 ships, services instrument NOW with export
  env-gated (unset OTEL_EXPORTER_OTLP_ENDPOINT = no-op). Logs dual-emit:
  JSON stdout stays (Cloud Run native logging) + OTLP to upstat. Operational
  telemetry (X-9) is SEPARATE from product analytics events (upstat
  /v1/events counters) — never mix the pipelines. Env names standard:
  OTEL_SERVICE_NAME, OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_EXPORTER_OTLP_HEADERS,
  OTEL_RESOURCE_ATTRIBUTES. ☑
- **X-10 Identity, profile & KYC tiers (RATIFIED, directive 2026-07-16)**: layered on
  X-1 — Google-only sign-in stays the sole credential; tiers add profile data and
  verification, never alternative logins. **Tier 0 — Google identity** (all
  products): firebase_uid + Google-verified email; grants all read/basic use.
  **Tier 1 — self-attested profile & location** (captured in product
  profile/settings; sensitive PII, never logged): apparule = bio + profile
  location {city, state, country} powering proximity-ranked designer
  recommendations ("near me") and delivery-address pre-fill (delivery address
  itself stays frozen per order); expendit = tax-jurisdiction location —
  state_of_residence for individuals, registered_address for company orgs —
  which resolves the remittance authority (State IRS vs FIRS); upstat = org
  timezone (IANA) only, for accurate report rendering and time-bucketing —
  deliberately the entire upstat requirement. **Tier 2 — provider-verified
  financial identity** (only where money moves or government filings
  generate; store provider refs + verification state, never raw government
  IDs): apparule designer payouts = Paystack bank resolution, BVN-backed
  (already ratified A-2 — canonized as the ecosystem pattern); expendit
  filing identity = TIN (+ RC number + registered address for companies)
  required at filing-pack generation (422 tax_identity_incomplete); v1
  verification is format validation + attestation, provider-verified arrives
  with direct e-filing (post-v1); upstat = N/A until billing enters the PRD.
  **Rules**: tiers gate capabilities, never sign-in; KYC state machines +
  error codes live in flow docs (apparule kyc_incomplete/post_unavailable is
  the template); tier-2 fields are high-sensitivity in every data-model §4
  classification; verification is delegated to the money/filing provider —
  no in-house document review. ☑
