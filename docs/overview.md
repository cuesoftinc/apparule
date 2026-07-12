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
