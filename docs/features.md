# Apparule — Granular Feature Register

> Every roadmap phase decomposed into implementation-sized units (each unit ≈
> one PR). Columns: unit · what it delivers · spec references · depends on.
> This is the build backlog; flows/engineering docs carry the acceptance
> detail. IDs are stable — reference them in PRs (`feat(F0-3): …`).

## Phase 0 — Home page + foundations

| ID | Unit | Delivers | Refs | Deps |
| --- | --- | --- | --- | --- |
| F0-1 | Design tokens package | tokens from `apparule/tokens` (Figma) as CSS vars + Tailwind config; light/dark | design.md §2, §7 | — |
| F0-2 | Web app shell | Next.js layout, nav (A1), footer (A10), theme switch, Lucide setup | pages.md A1/A10 | F0-1 |
| F0-3 | Hero + problem strip | A2 hero with device-frame loop, A3 stat cards | pages.md A2–A3 | F0-2 |
| F0-4 | Walkthrough + SMPL explainer | A4 scroll panel, A5 constellation animation asset | pages.md A4–A5, design.md MI-12 | F0-2 |
| F0-5 | Designers/open-source/community/cloud-vs-oss sections | A6–A9 | pages.md | F0-2 |
| F0-6 | Privacy page | APP-005 disclosure, retention copy from data-model §4 | pages.md A10, prd §6 | F0-2 |
| F0-7 | Analytics client wrapper | queued no-op upstat client; events per master registry | upstat api.md §3.4 | F0-2 |
| F0-8 | Docs hub links | GitBook space links, Scalar embed at /docs/api | openapi.yaml | F0-2 |

## Phase 1 — Auth + cloud access

| ID | Unit | Delivers | Refs | Deps |
| --- | --- | --- | --- | --- |
| F1-1 | Firebase project config | Google-only provider enforcement, sandbox-e306a wiring, Doppler stg secrets | flows/auth §1, X-1/X-5 | — |
| F1-2 | api/common: token verification middleware | Firebase Admin verify + provider check + ACCOUNT upsert (Firestore) | flows/auth §2/§4, engineering §2 | F1-1 |
| F1-3 | Web sign-in | single Google CTA screen, redirect fallback, session handling | flows/auth §2–4 | F1-1 |
| F1-4 | Flutter sign-in rewire | google_sign_in + firebase_auth; retire password screens | flows/auth §5 | F1-1 |
| F1-5 | Consent gate | consent sheet + GET/POST /consent + CONSENT_RECORD | prd §6, api.md | F1-2 |
| F1-6 | Instance requests | POST/GET /instance-requests + dashboard status page | architecture.md §4.2, prd APP-002, A-5 | F1-2 |
| F1-7 | Stub removal | delete legacy /api/auth/*, TODO(security-prd) retired | flows/auth §6 checklist | F1-2..4 |

## Phase 2 — Vault + capture

| ID | Unit | Delivers | Refs | Deps |
| --- | --- | --- | --- | --- |
| F2-1 | Firestore data layer | collections per data-model §2 hierarchy; rules (vault isolation); emulator tests | data-model, engineering §4 | F1-2 |
| F2-2 | QC gate in api/measure | pre-checks + pose QC + codes + thresholds config | capture-qc §1–2, §5 | — |
| F2-3 | Sessions API | POST/GET sessions (idempotent, multipart), Cloud Storage assets, retention field | flows/vault §1, api.md | F2-1, F2-2 |
| F2-4 | Confidence + plausibility | per-measurement confidence, height-suspect flag | capture-qc §3–4 | F2-2 |
| F2-5 | Manual entry + corrections | manual sessions, append-only corrections, sanity ranges | flows/vault §2 | F2-1 |
| F2-6 | Vault UI (web + Flutter) | B4/C7 cards, history, freshness ring MI-11; drafts + retry | pages.md, flows/vault edge cases | F2-3 |
| F2-7 | Capture UX | C6 silhouette/countdown/constellation; QC-code copy per table | flows/vault, MI-12 | F2-2, F2-6 |
| F2-8 | Retention job | daily purge of expired capture assets + unsaved sessions | data-model §4, flows/vault | F2-3 |
| F2-9 | Exports | PDF/CSV session exports, signed URLs | api.md, PLAT-004 | F2-3 |

## Phase 3 — Social graph & feed (T&S ships inside this phase)

| ID | Unit | Delivers | Refs | Deps |
| --- | --- | --- | --- | --- |
| F3-1 | Designer profiles | role enable, profile docs, KYC state (gate only, provider in F4-2) | data-model §5 | F2-1 |
| F3-2 | Posts | create (media ≤10, tags, price), post docs + Cloud Storage | pages.md B5, api.md §5 | F3-1 |
| F3-3 | Follow graph + feed | follows, home feed (recency+affinity), caught-up divider | pages.md B1/C2, api.md §5 | F3-2 |
| F3-4 | Explore + search | grid, filters, search | pages.md B2/C3 | F3-2 |
| F3-5 | Engagement | likes/saves/comments (optimistic, idempotent toggles) + counters | MI-1..3, MI-18, engineering §3 | F3-2 |
| F3-6 | PostCard component set | web + Flutter parity components (design.md §3 anatomy) | design.md, F0-1 | F3-2 |
| F3-7 | Trust & safety baseline | report/block, moderation queue, hide/suspend | A-6, engineering §2 | F3-2 |
| F3-8 | Notifications (in-app) | activity feed C10 + badge MI-16 | pages.md | F3-5 |

## Phase 4 — Commerce

| ID | Unit | Delivers | Refs | Deps |
| --- | --- | --- | --- | --- |
| F4-1 | Request stepper + snapshot | 3-step flow, server-frozen snapshot, idempotent submit | flows/request §1–2, order-lifecycle | F2-3, F3-2 |
| F4-2 | Paystack integration + KYC | init/webhook (signature), payout accounts, KYC gating | flows/request §3, A-1/A-2 | F3-1 |
| F4-3 | Platform ledger | held/released/refunded states + money invariant test | order-lifecycle §3, engineering §4 | F4-2 |
| F4-4 | Order lifecycle engine | state machine, expiry + auto-confirm jobs, reminders | order-lifecycle §1 | F4-1 |
| F4-5 | Order threads | messaging scoped to orders, images | order-lifecycle §5 | F4-1 |
| F4-6 | Orders UI | B3/C8 lists, detail, timeline MI-14, payment box MI-15 | pages.md | F4-1..4 |
| F4-7 | Disputes | dispute flow, payout freeze, support routing | flows/request §4 | F4-3 |
| F4-8 | Push notifications | FCM: quote/paid/status/reminders | pages.md C-notes, order-lifecycle §4 | F4-4 |
| F4-9 | Earnings dashboard | designer balance/payouts view | pages.md B6 | F4-3 |

## Phase 5 — SMPL (gated on A-3 licensing outcome)

| ID | Unit | Delivers | Refs | Deps |
| --- | --- | --- | --- | --- |
| F5-1 | Licensing decision execution | Meshcapade quote → go/no-go | A-3 | — |
| F5-2 | Accuracy benchmark harness | tape-vs-pipeline comparison suite | capture-qc §6 | — |
| F5-3 | Pipeline v2 | QC → fitting → mesh girths → confidence (`method: smpl_v1`) | architecture §5, capture-qc §4 | F5-1, F5-2 |
| F5-4 | GPU deploy (cloud) | inference node pool / GPU Cloud Run | deployment.md | F5-3 |
| F5-5 | Landing demo media upgrade | real-pipeline demo replaces preview | pages.md A5 | F5-3 |

## Cross-phase engineering units

| ID | Unit | Refs |
| --- | --- | --- |
| FX-1 | Error envelope + code middleware | engineering §1 |
| FX-2 | Authz capability middleware + matrix tests | engineering §2 |
| FX-3 | Rate limiting (shared Redis, X-5 index) | engineering §3 |
| FX-4 | Never-log CI grep gate | engineering §5 |
| FX-5 | build-and-test.yml + release.yml (tag-gated) | deployment.md, X-6 |
| FX-6 | cuesoft-iac apparule stack (Cloud Run ×2, WIF, Doppler) | deployment.md §2 |
| FX-7 | E2E smoke suite (release gate) | engineering §4 |
| FX-8 | OTel instrumentation (traces/metrics/log bridge, env-gated export → upstat) | engineering §Telemetry, X-9 |
