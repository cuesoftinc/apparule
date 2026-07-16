# Overview

Apparule is a fashion body-measurement platform. Users capture their body
measurements from their phone, and the platform turns those into sizing data
for a better-fitting shopping experience.

## Architecture

```
client                                   server
──────                                   ──────
web + dashboard (Next.js) ─┐             common api (Go)  ── GCP Cloud Run
                           ├─ Firebase /  measure api (Python, pose) ── Cloud Run
flutter mobile ────────────┘  Google auth
                                         data:
                                           Firebase Firestore & Storage
                                           Aiven Postgres & Valkey (Redis)
```

- **`web`** — Next.js marketing site + user dashboard (Firebase App Hosting).
- **`mobile`** — Flutter app (iOS/Android) for capturing measurements.
- **`api/common`** — Go service: authentication and core API (Cloud Run).
- **`api/measure`** — Python service: MediaPipe pose-based body measurement.
- **Auth** — Firebase Authentication / Google sign-in.
- **Data** — Firebase Firestore & Storage; Aiven Postgres & Valkey (Redis).

See [setup.md](setup.md) to run the stack locally, and the
[repository structure](../README.md#repository-structure) in the README.

## Product & design documentation

- [prd.md](prd.md) — product requirements breakdown (personas, requirements, compliance, open questions)
- [architecture.md](architecture.md) — current vs target system design, sequences, SMPL pipeline
- [data-model.md](data-model.md) — entities, storage mapping, data classification
- [api.md](api.md) — current + target API surface and gap analysis
- [roadmap.md](roadmap.md) — phased plan with cross-repo dependencies
- [design.md](design.md) + [pages.md](pages.md) — design language, screens, microinteractions
- [order-lifecycle.md](order-lifecycle.md) — commission order state machine, permissions, notifications
- [decisions.md](decisions.md) — the open-decision register: ratify to unblock phases
