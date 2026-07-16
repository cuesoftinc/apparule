# Apparule — Roadmap

> Phases turn the PRD/current-state gap (api.md §3) into an ordered plan. Each
> phase is shippable on its own. No code is implied to exist yet — this is the
> agreed sequence for when implementation starts.

## Phase 0 — Web property foundation

**Goal:** apparule.cuesoft.io stops being a template and becomes the product's
home. Everything here is achievable without new backend capabilities.

| Item | Requirement | Notes |
| --- | --- | --- |
| Landing page: hero, problem statement, cloud-vs-OSS comparison, CTAs | APP-001, PRD §3/§6 | Figma Home canvas is currently empty — either the design pass happens first or we ship a standards-based layout and retrofit (prd.md §8.5) |
| Interactive walkthrough (static/scripted, no live pipeline) | PRD §3 | Multi-step visualization of measurement entry → report |
| Docs hub `/docs` with deploy guides + SMPL explainer | APP-003 (explainer), APP-004 (seed) | Content sources: repo docs, README |
| API reference `/docs/api` rendering api/measure OpenAPI + hand-written api/common spec | APP-004 | Search can be client-side (flexsearch) at this scale |
| Privacy disclosure page | APP-005, D3 | Links to Apparule clause on privacy.cuesoft.io |
| Analytics events: Demo Starts, GitHub Clicks | ECO-ANALYTICS | **Blocked by D2** (Upstat event API) — ship with a no-op/queued client wrapper so events flow the day D2 lands |

**Exit criteria:** PRD §3 sitemap fully served; APP-001/005 acceptance met;
Lighthouse mobile score ≥ 90 (PRD's mobile-first bias).

## Phase 1 — Trustworthy auth + cloud access flow

**Goal:** APP-002 end-to-end, on real identity.

| Item | Requirement | Notes |
| --- | --- | --- |
| Replace auth stubs: verify Google ID tokens properly; implement email link/OTP or drop the endpoint | PLAT-003 | Independent of D1; removes the `TODO(security-prd)` debt |
| `account.cuesoft.io` integration once contract exists | ECO-AUTH, D1 | Until then the hardened local auth carries the flow |
| Consent gate (ToS + retention + accuracy disclaimer) | PRD §7 | `CONSENT_RECORD` model |
| Instance request flow + minimal dashboard page | APP-002 | Queue + manual ops provisioning via existing helm chart (prd.md §8.2) |

**Exit criteria:** a signed-in user can accept terms and file an instance
request; requests visible with status; zero unauthenticated access to any
record endpoint.

## Phase 2 — Measurement platform (the core product)

**Goal:** PLAT-001/002/004 — records exist server-side and survive the phone.

| Item | Requirement |
| --- | --- |
| Firestore data layer (X-5) + repository layer | data-model.md |
| Customers CRUD + workspace scoping | PLAT-002 |
| Measurement sessions: upload → internal api/measure call → persisted results | PLAT-001 |
| Manual corrections (append-only) | data-model.md §2 |
| Exports (PDF/CSV, signed URLs) | PLAT-004 |
| Flutter: wire capture flow to sessions API; dashboard: records UI | PLAT-001/002 |
| Retention automation for capture assets | PRD §7 |

**Exit criteria:** capture on phone → stored session → visible in dashboard →
exported PDF, with images auto-purged at `retention_until`.

## Phase 3 — SMPL pipeline

**Goal:** APP-003 (demo) fully honest, PLAT-005 delivering girth measurements.

| Item | Notes |
| --- | --- |
| **Licensing decision first** (risk R1) | SMPL commercial license vs alternative body model — gates everything below for cloud use |
| Research spike: single-image SMPL fitting (HMR-family) accuracy on target demographics | Includes accuracy benchmark harness vs tape measurements |
| Pipeline v2: QC gate → fitting → mesh girths → confidence (architecture.md §5) | `method: smpl_v1`, additive response schema |
| Demo media for landing | APP-003 — can precede production pipeline |
| GPU inference deployment (cloud node pool) | Self-hosted default remains CPU 2-D method |

**Exit criteria:** side-by-side accuracy report published in docs; cloud
sessions can select `smpl_v1`; landing demo reflects the real pipeline.

## Dependencies

| ID | Dependency | Owner | Blocks |
| --- | --- | --- | --- |
| D1 | `account.cuesoft.io` auth contract | Cuesoft ecosystem | Phase 1 (final shape), APP-002 |
| D2 | Upstat generic event-ingestion API | upstat repo (its PRD names it the ecosystem tracker) | ECO-ANALYTICS in Phase 0 |
| D3 | Apparule clause on privacy.cuesoft.io | Cuesoft legal/content | APP-005 copy |
| R1 | SMPL commercial licensing | Product decision | Phase 3 in cloud |

## Sequencing rationale

Phase 0 needs no one's permission and creates the public face; Phase 1 makes
identity real (a hard precondition for storing body data); Phase 2 is the
value core and the biggest engineering slice; Phase 3 is the differentiator
but carries research + licensing risk, so it rides last with a demo shipped
early (Phase 0 explainer, Phase 3 media upgrade).

---

## Revision — social commerce expansion (2026-07-16)

The 2026-07-16 directive (instagram-feel social commerce: posts, likes,
requests with measurement snapshots, designer payments) re-shapes the phases.
Phases 0–1 stand (home page per pages.md Part A; real auth). The build order
after them becomes:

- **Phase 2 — Vault + capture** (unchanged core, reframed): measurement vault
  = the social profile's data spine (pages.md B4/C6-C7).
- **Phase 3 — Social graph & feed**: designer profiles, posts, follows,
  likes/saves/comments, explore (SOC-001…003, 007).
- **Phase 4 — Commerce**: requests + snapshots + order lifecycle + threads +
  payments/escrow/payouts (SOC-004…006) — payment provider + KYC decisions
  gate this phase.
- **Phase 5 — SMPL pipeline** (was Phase 3): unchanged content; now also
  feeds richer snapshots into requests.

Trust & safety (SOC-009: report/block/moderation) ships **with** Phase 3 —
UGC without moderation doesn't go public. Platform parity note: web dashboard
and mobile ship each phase together (shared component naming, design.md §6).
