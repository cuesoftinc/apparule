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
  tokens (OIDC-compatible). The `account.cuesoft.io` facade fronts this later
  without contract changes. Environment/secrets live in **Doppler**
  (`cueprise/cuesoft_stg`; see also the `cuesoft-iac` project) — CLI token
  currently expired (`doppler login` to refresh); config names to be mirrored
  into docs once readable. ☑
- **X-2 Docs platform**: GitBook org with **one space per product**,
  Git-synced from each repo's `docs/`; API refs rendered by **Scalar** from
  OpenAPI, embedded in each docs space. ☑
