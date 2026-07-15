# Apparule — Product Requirements Breakdown

> Source: "Apparule Product Requirement Document" (provided 2026-07-15) combined
> with the repository state on `main`. The linked
> [Figma file](https://www.figma.com/design/34GbYXm8TpxMMUaAGGuwMM/Apparule)
> currently contains an empty "Home" canvas, so the PRD's component table is the
> authoritative sitemap until designs land.
>
> Markers used throughout the docs set: **[PRD]** = stated requirement,
> **[Current]** = verified repository fact, **[Proposed]** = design decision
> introduced by this breakdown that needs ratification.

## 1. Product definition

Apparule is an open-source measurement and apparel platform: it collects,
stores, and manages customer physical dimensions and bridges that body data
into garment-production workflows. **[PRD]**

Two distinct things carry the name and must not be conflated:

| Surface | What it is | Commercial status |
| --- | --- | --- |
| The open-source product (this repo) | Go core API, Python measurement service, Next.js web, Flutter mobile | Free, self-hostable |
| Apparule Cloud | Hosted instances of the same stack, managed by Cuesoft | Separate commercial offering **[PRD §5]** |

`apparule.cuesoft.io` is the single web property serving both: product-led
landing, documentation hub, and the cloud access point. **[PRD §1.1]**

## 2. Personas and jobs-to-be-done

| Persona | Job-to-be-done | Primary surface |
| --- | --- | --- |
| Fashion SMEs & tailors | Replace paper/manual measurement records; retrieve a customer's dimensions when producing a garment | Mobile app (capture) + cloud dashboard (manage) |
| Apparel product evaluators | Assess whether Apparule fits their workflow before committing | Landing page, interactive walkthrough, demo booking |
| Software engineers | Integrate measurement APIs into their own apps; contribute to the project | Developer docs, API reference, GitHub |
| Internal Cuesoft teams (CueLABS™) | Product experimentation and talent development | Whole stack |

Mobile-first bias: tailors and fashion SMEs predominantly operate on phones, so
measurement entry must be touch-friendly and responsive. **[PRD §5]**

## 3. Functional requirements

### 3.1 Stated requirements (web property)

| ID | Requirement | Priority | Expanded acceptance criteria |
| --- | --- | --- | --- |
| APP-001 | Open-Source Gateway | Must | Prominent GitHub link + contribution guidelines from the landing page; repository README/CONTRIBUTING are the landing targets. |
| APP-002 | Cloud Access Flow | Must | Sign-in via `account.cuesoft.io`; authenticated users can request a cloud instance; request is tracked and acknowledged. Users must accept product-specific ToS (data retention + accuracy disclaimer) before cloud access. **[PRD §7]** |
| APP-003 | SMPL Pipeline Demo | Should | Visual/video walkthrough of the SMPL-based measurement process embedded on the landing page. |
| APP-004 | API Reference | Should | Searchable API documentation for third-party integration. |
| APP-005 | Privacy Disclosure | Must | Explicit page/section describing how measurements and personal physical data are handled, linking to the Apparule clause in `privacy.cuesoft.io`. |

### 3.2 Ecosystem requirements

| ID | Requirement | Notes |
| --- | --- | --- |
| ECO-AUTH | All login/session management via `account.cuesoft.io` | External service — does not exist in this repo; see roadmap dependency D1. **[PRD §4.2]** |
| ECO-SUPPORT | Route active users needing help to `clients.cuesoft.io` | Link-out only in v1. |
| ECO-ANALYTICS | Track "Demo Starts" and "GitHub Clicks" via Upstat | Depends on Upstat exposing a generic event-ingestion API (cross-repo dependency D2 — Upstat currently has none). |

### 3.3 Implied platform requirements **[Proposed]**

The executive summary ("collecting, storing, and managing customer physical
dimensions … actionable garment production workflows") implies product
capabilities beyond the web property. Made explicit so they can be scheduled:

| ID | Requirement | Rationale |
| --- | --- | --- |
| PLAT-001 | Server-side measurement records | Today `POST /measure` is stateless; nothing is stored anywhere but the phone. "Storing and managing" requires persistent records. |
| PLAT-002 | Customer management | A tailor manages many customers, each with measurement history. |
| PLAT-003 | Real authentication | Both current auth endpoints are stubs (`TODO(security-prd)` in `internal/auth/auth.go`): Google login does not verify the ID token; email login is a logged no-op. Real identity is a precondition for storing sensitive records. |
| PLAT-004 | Garment-workflow export | The "bridge to production" — export measurement sets in shareable/printable form (v1: PDF/CSV export; later: size-chart mapping). |
| PLAT-005 | SMPL measurement pipeline | Upgrade from the current 2-D landmark approach to SMPL-based 3-D body modeling (see architecture.md §5 for the technical gap and licensing note). |

## 4. Non-goals (v1)

- Building `account.cuesoft.io`, `clients.cuesoft.io`, or `privacy.cuesoft.io`
  themselves — they are ecosystem dependencies, consumed not implemented here.
- E-commerce/checkout, garment CAD, or pattern drafting.
- Real-time in-browser 3-D fitting; the SMPL demo is pre-rendered media. **[PRD APP-003]**
- Direct integrations with garment factories (v1 bridges via exports).

## 5. Brand & content requirements

- Aesthetic: product-led, technical, visual; high-quality product screenshots,
  workflow diagrams, code-style documentation blocks. **[PRD §2]**
- Subtle Afrocentric geometric patterns for Cuesoft ecosystem alignment. **[PRD §2]**
- Terminology: "AI-assisted body modeling" in marketing copy; "SMPL pipeline"
  reserved for developer docs. **[PRD §6]**
- CTAs: "Try Apparule Cloud", "View on GitHub", "Book a Demo". **[PRD §6]**
- Case studies: retail, fashion SMEs, measurement management. **[PRD §6]**

## 6. Compliance & safety requirements

| Concern | Requirement |
| --- | --- |
| Data classification | Measurements + body images are **high-sensitivity personal data**; handling rules in data-model.md §4. **[PRD §7]** |
| Privacy disclosure | Site links to the Apparule-specific clause in `privacy.cuesoft.io` (APP-005). |
| Terms gate | Cloud users must accept product-specific ToS covering data retention and measurement-accuracy disclaimers *before* access. Consent must be recorded (data-model.md `ConsentRecord`). |
| Accuracy disclaimer | Measurements are estimates; garment production decisions are the user's responsibility. Surface wherever measurements render. **[Proposed]** |

## 7. Success metrics

| Metric | Source | Requirement |
| --- | --- | --- |
| Demo Starts | Upstat event from walkthrough/demo CTA | ECO-ANALYTICS **[PRD]** |
| GitHub Clicks | Upstat event from APP-001 gateway | ECO-ANALYTICS **[PRD]** |
| Cloud instance requests | api/common (APP-002 flow) | **[Proposed]** |
| Measurement sessions created / stored records | api/common | **[Proposed]** — the core-value metric |

## 8. Open questions

1. **`account.cuesoft.io` contract** — protocol (OIDC? opaque token introspection?),
   token audience/claims, and timeline. Blocks APP-002 and PLAT-003's final shape
   (roadmap D1). Interim: local JWT auth hardened enough for records **[Proposed]**.
2. **Cloud instance model** — "request a cloud instance" reads as
   instance-per-customer provisioning rather than one multi-tenant app. v1 treats
   it as a *request queue + manual provisioning* (helm chart already exists per
   instance) **[Proposed]** — confirm.
3. **SMPL licensing** — SMPL model weights are free for research; commercial use
   requires a license from Meshcapade/MPI. The hosted commercial cloud likely
   needs SMPL commercial licensing or an alternative body model. Must be resolved
   before PLAT-005 ships in cloud (roadmap risk R1).
4. **Where records live** — README names both Firestore and Aiven Postgres.
   data-model.md proposes Postgres as the system of record; confirm.
5. **Figma designs** — Home canvas is empty; landing implementation (roadmap P0)
   needs the design pass, or we proceed with a standards-based layout and
   retrofit.

---

## 9. Scope expansion — social commerce (2026-07-16) **[Directive]**

Apparule is a **social network**: users add/take measurements; designers post
outfits; users like, save, share, and **commission** outfits — a request
carries the user's measurement snapshot; the designer produces the garment and
**gets paid**. Look and feel: **instagram.com** (design.md). Platform
structure: public home page + web dashboard + mobile app (mobile is the
primary social surface; all products converge on this three-surface parity).

- New requirement register: SOC-001…010 in [pages.md](pages.md) (feature
  delta table). PLAT-001/002 (records) become the **measurement vault**
  feeding SOC-004.
- Page/screen inventory: [pages.md](pages.md). Design system +
  microinteractions: [design.md](design.md).
- New open questions: payment provider + escrow model + platform fee
  (SOC-006); UGC trust & safety baseline (SOC-009) required before public
  launch; designer verification (KYC for payouts).
- Docs platform **[Directive]**: product docs on GitBook (Git-synced from
  this `docs/` folder); API reference via Scalar from OpenAPI.
