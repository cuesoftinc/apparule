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
  live in Doppler `<project>/stg`. Because these repos are **open-source**,
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

## Mobile (apparule-only)

> Mobile is authorized for apparule alone (2026-07-21, explicit) — no
> sibling product carries a mobile app in its PRD. These rulings execute the
> ratified `oss-engineering-standards` SKILL.md "Mobile (Flutter)
> implementation standard" against `mobile/flutter`; full detail lives in
> [mobile-implementation.md](mobile-implementation.md).

- **M-1 Flutter standard ratification (RATIFIED 2026-07-21)**: the org
  SKILL.md canon (`oss-engineering-standards` PR #120) governs
  `mobile/flutter`; mobile-implementation.md carries the full contract.
  Toolchain: **Flutter 3.44.7 / Dart 3.12**, pinned via **FVM**
  (`.fvmrc` is the source of truth, mirrored in `pubspec.yaml`); Android
  floor **API 24**, iOS floor 15 (Firebase iOS SDK 12's minimum — the
  original floor-13 ratification predated the §9 auth wiring); **SwiftPM**
  is the iOS dependency
  default (CocoaPods' registry goes read-only 2026-12-02, so no new
  CocoaPods dependency is added — the salvaged iOS shell migrates to
  SwiftPM in the restructure phase). ☑
- **M-2 Architecture & state acceptances (RATIFIED 2026-07-21)**: the
  official Flutter **MVVM + Repository** vocabulary, organized
  **feature-first** (`lib/src/features/<feature>/{presentation,domain,
  data}` + `src/{app,routing,core}` — no separate `application/` layer);
  **Riverpod 3 with codegen** for state and DI (provider overrides per
  environment; no `get_it` second container) — Bloc rejected as
  boilerplate for this app's size, GetX rejected as not standards-grade,
  and the legacy `provider ^6.0.5` package is superseded outright, not
  bridged; **go_router + go_router_builder** typed routes accepted **in
  maintenance mode** (first-party; revisit only on a successor package),
  `StatefulShellRoute` driving the Home·Explore·➕·Orders·Profile tab
  shell (pages.md Part C) with one top-level auth `redirect` off the
  session provider. ☑
- **M-3 Legacy auth retirement — X-1 execution via the quarantine
  pattern (RATIFIED 2026-07-21, revised same day per user directive)**:
  the entire legacy `lib/src/features/auth/` (9 files: password +
  phone/SMS + email-OTP flows, the `sms_autofill` dependency,
  `form_provider`) is **quarantined into `lib/legacy/` at the auth
  cutover, never migrated** — canon-violation CV-1 in the legacy audit
  ledger — and actually removed only after the Google-only replacement
  ships AND the user gives an explicit removal go (the web legacy
  pattern: route-by-route replacement, end-of-program authorized
  sweeps). Replacement is the Google-only Firebase flow (§9 of
  mobile-implementation.md); the retirement list per **flows/auth.md
  §5**: `login_page` becomes the single auth screen, and
  `sign_up_form`, `sign_up_screen`, `forgot_password`, `reset_password`,
  `verify_email`, `sms_verification`, `verify_account` are retired by
  name. `models/user.dart` (prefs-string identity, CV-2) quarantines
  with it. Quarantined code is excluded from assets, analysis, CI, and
  builds (mobile-implementation.md §11). ☑
- **M-4 Android API floor (RATIFIED 2026-07-21)**: **minSdkVersion 24**
  (the legacy value, confirmed against the ratified standard's floor) —
  carried forward, not raised. The Android project is regenerated to
  current tooling (AGP 8+, Kotlin DSL, package renamed off the stale
  `com.example.apparule` to match the real `io.cuesoft.apparule`
  applicationId, ARCore/Sceneform dependencies dropped, DEBUG-key release
  signing replaced) as part of the toolchain-floor migration step — no
  behavior change. ☑
- **M-5 Mock-first sequencing — API last (RATIFIED 2026-07-21)**: mirrors
  the web `TEST_MODE` contract (web-implementation.md §5) — every
  repository ships abstract with `*Remote` and `*Fake` implementations;
  fakes read seeded narrative JSON from flavor-scoped `assets/seed/`
  (`dev`/`stg` entrypoints run entirely on fakes), tied to the **same
  designer/order/vault personas** as the web mock server's seed
  (web-implementation.md §6) so both clients tell one coherent demo.
  API wiring is the **last** migration step, behind unchanged repository
  interfaces — no ViewModel or screen changes at that step. ☑
- **M-6 Single-photo measurement reaffirmation (RATIFIED 2026-07-21)**:
  the **one frontal photo + height** canon (api.md `POST /measure`;
  capture-qc.md; flows/vault.md §1) is unchanged by the mobile rebuild —
  the legacy two-pose `guide_screen.dart` (front + side) is **rewritten**
  to one pose, not extended (CV-4). C6 owns the silhouette overlay + 3-2-1
  countdown (the legacy `countdown.dart` is salvaged as-is), the
  `mediapipe_2d_v2` height-scale correction, capture-qc.md's
  first-failure-only QC surfacing, and a manual-entry fallback; results
  save into the vault (C7). ☑
- **M-7 Flavor model — two flavors, sandbox is production (RATIFIED
  2026-07-22, user directive)**: mobile ships exactly `dev` (fake
  repositories, `applicationIdSuffix ".dev"`) and `prod` (bare
  `io.cuesoft.apparule`, Firebase `sandbox-e306a`, Doppler `stg`
  config) — the CueLABS environment model treats the sandbox account
  as production, so a `prd`-vs-`stg` split encodes an environment
  that does not exist (X-6). The generic dev/stg/prd trio from the
  industry-standard research is explicitly rejected. A third flavor
  appears only if a separate production environment is ratified;
  the bare application id already rides `prod` so identity migrates
  cleanly. ☑
