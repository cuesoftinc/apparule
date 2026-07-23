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

## A-9 · Inches are the default display unit

**Recommendation ⭐:** inches as the default measurement DISPLAY unit —
Nigerian tailors work in inches. Scope: display + input defaults on web AND
mobile (formatters, measurement cards, manual entry, the capture height
field); cm stays canonical in storage, API payloads (`value_cm`,
`user_height_cm`), and the QC pipeline; the MI-13 cm/in toggle persists the
user's choice.

☑ Ratified 2026-07-23

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
  builds (mobile-implementation.md §11). *Executed 2026-07-22*: both
  removal conditions met — the Google-only replacement shipped (C1 at
  the auth cutover; QA-convergence ledger all-PASS/FIXED) and the user
  gave the explicit removal go (directive 2026-07-22) — the quarantine
  (`lib/legacy/`, `assets/legacy/`, `legacy/web-scaffold/`,
  `legacy/android-agp7/`) was deleted with its excludes;
  mobile-implementation.md §11 carries the removed register. ☑
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
  (`dev`/`prod` entrypoints run entirely on fakes), tied to the **same
  designer/order/vault personas** as the web mock server's seed
  (web-implementation.md §6) so both clients tell one coherent demo.
  API wiring is the **last** migration step, behind unchanged repository
  interfaces — no ViewModel or screen changes at that step.
  **Addendum — auth posture (user, 2026-07-22)**: the TEST_MODE-parity
  fakes (both flavors riding `AuthRepositoryFake` over the real
  session-lifecycle seam) are the **ratified state until phase 4** —
  the Firebase wiring steps stay documented
  (mobile-implementation.md §9) but gated behind an explicit
  phase-4 go. ☑
- **M-6 Single-photo measurement reaffirmation (RATIFIED 2026-07-21 —
  REVERSED by M-10, 2026-07-22; kept for the audit trail)**: reaffirmed
  the **one frontal photo + height** canon as the docs then stood (api.md
  `POST /measure`; capture-qc.md; flows/vault.md §1), leaving it
  unchanged by the mobile rebuild — the legacy two-pose
  `guide_screen.dart` (front + side) was to be **rewritten** to one
  pose, not extended (CV-4). C6 kept the silhouette overlay + 3-2-1
  countdown (the legacy `countdown.dart` salvaged as-is), the
  `mediapipe_2d_v2` height-scale correction, capture-qc.md's
  first-failure-only QC surfacing, and the manual-entry fallback — all
  of which carried into M-10's two-photo flow, the canon now in force. ☑
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
- **M-8 Canvas-first rule (RATIFIED 2026-07-22, user directive — org
  canon, `oss-engineering-standards` SKILL #127)**: every shipped screen
  has a Figma frame; a frameless screen is **designed first or dropped**.
  Applied same-day, both ways: the mobile `/create` composer placeholder
  was **dropped** (no frame — the designer composer arrives
  designed-first with its own canvas frames), and the C6 guide — where
  "existing guide screens restyled" had resolved to frameless 2023
  legacy art — was **designed first** (six GuidePage frames landed
  before the rebuild lane touched the screen). The canvas leads;
  pages.md rows may not point at unframed screens. ☑
- **M-9 Centered header-bar titles (RATIFIED 2026-07-22, user
  directive)**: sub and over-media app-bar titles center on the **full
  bar width** — an absolute, full-width, center-aligned text layer over
  the bar, never an in-flow element between the slots (in-flow titles
  grow into hidden trailing slots and skew off-center). Leading/trailing
  slots stay in-flow at the edges; the title's horizontal padding
  reserves the widest slot. `root` bars (brand wordmark/username, left)
  are exempt. **Chrome-scoped**: the rule governs header bars only —
  in-content page titles (the dashboard's h1s, IG-desktop idiom) stay
  left-aligned; never center page-body titles. Spec: design.md §8.2b
  AppBar row. ☑
- **M-10 Two-photo capture (RATIFIED 2026-07-22, user directive —
  REVERSES M-6)**: the product mechanic is **two photos — front + side
  (right profile) — plus height**. The reversal chain, honestly: M-6 was
  ratified from the docs' one-photo contracts as they then stood (api.md
  `POST /measure`, capture-qc.md, flows/vault.md §1); the user ruled that
  the web marketing copy ("Two photos. A perfect fit.") was the true
  product intent all along — the **docs, not the copy, had drifted**.
  The contracts now carry the two-photo canon: api.md `POST /measure`
  takes multipart `image_front` + `image_side` + `user_height_cm`;
  capture-qc.md defines **per-pose QC** (the front pose keeps the
  frontality table; the side pose gets a profile-orientation check —
  `not_side_profile` — and an arms-relaxed check in place of the front
  pose's arms rule; first-failure-only **per pose**, and a pose-2 failure
  never discards an accepted pose 1); flows/vault.md §1 runs the
  two-capture sequence (front → side → processing; a QC retry re-enters
  the failing pose, never advances the pose counter); pages.md C6 and
  mobile-implementation.md §10 describe the two-pose flow with the 5-step
  guide (side pose included); the `mediapipe_2d_v2` formula gains the
  side-pose contribution — girth estimation from two views — marked
  **[Directive: measurement pipeline recalibration needed]** for the
  backend phase. ☑
- **M-11 Unified create semantics (RATIFIED 2026-07-22, user
  directive)**: the ➕/Create action opens a **two-option chooser on
  both platforms** — "Take measurements" (capture) and "Post an outfit"
  (designer-gated: non-designers route to become-a-designer). Supersedes
  the divergence where web Create was composer-only and mobile ➕ was
  capture-only — each client was per its contract; the **contracts** had
  diverged. The mobile composer (**C15**) is **authorized design-first**
  (M-8): canvas frames come next, mirroring the web B5 composer, and the
  build follows once the frames ratify; until C15 ships, mobile's
  chooser offers capture + become-a-designer only. ☑
- **M-12 Web measurement capture is upload-only (RATIFIED 2026-07-22,
  user directive)**: web users **upload** the two photos — front + side
  files into the same endpoint and per-pose QC pipeline (M-10). The
  webcam capture flow is **removed** from web: full-body webcam capture
  is rejected UX (desk-height lens; no way to frame yourself and reach
  the controls). The web vault entry surfaces a "best experience: guided
  capture on the mobile app" hint; mobile keeps the live guided camera.
  The composer create flow is upload/import on **both** platforms
  (already the web idiom; C15 mobile uses the device picker) — no live
  camera enters the composer. api.md is unchanged beyond M-10: the
  endpoint takes two images regardless of source. ☑
