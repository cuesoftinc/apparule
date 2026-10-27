# Deploy Runbook — GCP + Aiven

> For the person deploying Apparule to the company's GCP project and Aiven
> account. It turns [deployment.md](deployment.md) and the
> [system design](system-design.md) §10 into steps. Everything in the repo
> is ready; the steps below are the parts only an account owner can do.
> Work through them in order: each part lists what to create and the exact
> names and values the code expects.

## 0. Read first: merging this branch changes the live website

The website rides **Firebase App Hosting rollouts from `main`**. After this
branch merges, App Hosting rebuilds `web/`, and how it behaves depends on
one build variable:

- **`NEXT_PUBLIC_TEST_MODE=1`**: the site runs on its built-in mock API,
  exactly as today. **Keep this set until the backend is deployed (§9).**
- **Unset**: the site signs in with Firebase and calls the real API. If
  the API or the Firebase config isn't there yet, sign-in and every
  dashboard screen fail.

So: merge, check the site still works in TEST_MODE, and only remove the
flag in §9. The Flutter app stays on its fake repositories until its
remote set ships.

## 1. What runs where

| Unit | Runs on | Image / source | Notes |
| --- | --- | --- | --- |
| `web` | Firebase App Hosting | `web/` from `main` | Proxies `/api/v1/*` to `apparule-api-common` (no load balancer, no browser CORS); uploads is reached at its `run.app` URL |
| `apparule-api-common` | Cloud Run service | `cuesoft/apparule-api-common` | Go. The only Postgres client; receives Paystack webhooks. Serves the `/internal/jobs/<name>` sweeps. Kafka consumers + outbox run while an instance is up |
| `apparule-api-uploads` | Cloud Run service | `cuesoft/apparule-api-uploads` | Node upload gateway (`POST /api/v1/uploads`) |
| `apparule-api-segmentation` | Cloud Run service | `cuesoft/apparule-api-segmentation` | Python, MediaPipe. Kafka only; reached only by wake-ups |
| `apparule-api-commerce` | Cloud Run service | `cuesoft/apparule-api-commerce` | Python. Paystack, FCM, Brevo. Kafka only |
| `apparule-{captures,orders,reconcile,retention}` | Cloud Scheduler jobs | n/a | `POST /internal/jobs/<name>` on `apparule-api-common` with an OIDC token; created paused until the handlers are deployed |
| Postgres, Valkey | the shared Aiven `sandbox-db` and `sandbox-cache` | n/a | database `apparule`, user `apparule_app`; keys `apparule:*` |
| Kafka | the CueLABS shared Aiven service | n/a | shared with Expendit and Upstat (X-11); SASL user `apparule` with topic ACLs |
| Object storage | `sandbox-e306a.firebasestorage.app` | n/a | prefix `apparule/stg/`; media by signed URL only |

Images are built and deployed by `.github/workflows/release.yml` when a
`v*` tag is created (§8). **Your infrastructure code creates the resources;
the workflow only swaps their image digests.**

### 1.1 Everything scales to zero

No service runs while nobody uses the app (S-9 as amended). Kafka needs a
running consumer, and Cloud Run starts one only for an HTTP request, so each
service that publishes wakes the one that consumes with a `GET /health`:

```
app/browser → common (creates the capture session) → uploads (photos)
uploads ──capture.uploaded──▶ Kafka, then wakes common
common ──capture.ready on cuelabs.requests──▶ Kafka, then wakes segmentation
segmentation ──capture.measured on cuelabs.results──▶ Kafka, then wakes common
(commerce works the same way for orders, webhooks, payouts and notifications)
```

CPU is allocated only while a request is in flight (no always-on instance,
worker pool or Cloud Run job), so a woken instance consumes while requests
are open and Cloud Run retires it when idle (up to about 15 minutes). The `captures` sweep is the safety net:
every minute it re-sends an overdue capture once and wakes common and
segmentation while work is pending. The first capture after a quiet period
takes longer (cold start, MediaPipe load, consumer-group join); later ones
take a few seconds.

## 2. Firebase

Google sign-in only (X-1). A Firebase project is the GCP project, so use the
same project as Cloud Run (`sandbox-e306a`).

1. **Authentication → Sign-in method → Google → Enable.** Disable
   email/password (flows/auth.md §6).
2. **Authentication → Settings → Authorized domains**: add
   `apparule.cuesoft.io` and the App Hosting backend's own domain
   (`<backend>--<project>.<region>.hosted.app`).
3. **Project settings → Your apps → Web app**: note `apiKey`, `authDomain`
   and `projectId` for §6. They are public by design.
4. **Cloud Messaging**: enable the Firebase Cloud Messaging API (V1);
   `commerce` sends with its service account (§5), so no server key.
5. For the Flutter app: `flutterfire configure` per flavor (needs
   `firebase login`); it produces the options files the app's real auth and
   remote repositories wait for.

The API verifies tokens against Google's public keys and the project ID, so
`common` needs **no Firebase key or service-account JSON**.

## 3. Aiven

### 3.1 Postgres

Use a dedicated database and a **non-superuser** role. Row-level security
(S-11) does not apply to superusers or roles with `BYPASSRLS`, and Aiven's
`avnadmin` should not run the app. As `avnadmin`:

```sql
CREATE ROLE apparule_app LOGIN PASSWORD '<generate>' NOSUPERUSER NOBYPASSRLS;
CREATE DATABASE apparule OWNER apparule_app;
```

`DATABASE_URL` =
`postgres://apparule_app:<password>@<host>:<port>/apparule?sslmode=require`.
Tables are created by the app itself on start (migrations under an advisory
lock); there is nothing to run by hand. The database lives on the shared
Aiven `sandbox-db`.

### 3.2 Kafka (the CueLABS shared bus)

Apparule uses the shared service and its three lanes
(`cuelabs.uploads`, `cuelabs.requests`, `cuelabs.results`, 2 partitions
each); the rules are in the CueLABS delivery standard
(`references/shared-messaging.md`). If Expendit's deploy already created
them, there is nothing to add but the user. Apparule never creates topics.

Create **one SASL user, `apparule`**, with topic ACLs for read and write on
the three `cuelabs.*` topics and on consumer groups starting with `apparule-`
(`apparule-common`, `apparule-segmentation`, `apparule-commerce`). All four
services use it. If the free plan refuses SASL, use client certificates.

**Keep-alive belongs to Expendit**: its reaper keeps the service awake and
powers it back on. Apparule runs no heartbeat or watchdog. While the bus is
away, uploads answer `503` with `Retry-After`, the outbox holds Apparule's
messages, and overdue captures are re-sent from Postgres once it returns.

Connection settings for every service: `KAFKA_BROKERS` (`host:port`),
`KAFKA_USERNAME`, `KAFKA_PASSWORD`, and `KAFKA_SSL_CA` = the **text** of
Aiven's CA certificate (`-----BEGIN CERTIFICATE-----…`). The clients use
SASL/SCRAM-SHA-256 over TLS.

### 3.3 Redis

The shared Aiven Valkey `sandbox-cache`, user `apparule`, whose ACL allows
the keys `apparule:*` only: `REDIS_HOST`, `REDIS_PORT`, `REDIS_USERNAME`,
`REDIS_PASSWORD`, `REDIS_TLS=true`, `REDIS_KEY_PREFIX=apparule` (the
default). Only `common` uses it, for rate
limits and the upload quota; if it is unreachable the limits fail open.

## 4. Cloud Storage

1. Use the shared bucket `sandbox-e306a.firebasestorage.app` with
   **uniform bucket-level access**. Apparule uses only the prefix `apparule/stg/`.
2. Lifecycle rules: **delete objects older than 1 day with prefix
   `apparule/stg/tmp/`**, and the same for **`apparule/stg/compute/`**.
3. No object is public: every file is served by a signed URL.

## 5. Service accounts and IAM

| Service account | Used by | Roles |
| --- | --- | --- |
| `apparule-common` | common | `roles/storage.objectAdmin` on the bucket, condition (A); `roles/iam.serviceAccountTokenCreator` **on itself** (signed URLs); `roles/run.invoker` on segmentation and commerce (to wake them) |
| `apparule-uploads` | uploads | `roles/storage.objectCreator`, condition (B) |
| `apparule-segmentation` | segmentation | `roles/storage.objectViewer`, condition (C); `roles/storage.objectCreator`, condition (D) |
| `apparule-commerce` | commerce | `roles/storage.objectAdmin`, condition (D); `roles/firebasecloudmessaging.admin` on the project |
| `scheduler-invoker` | Cloud Scheduler | OIDC token on `POST /internal/jobs/<name>`; audience is the common service URL |
| `apparule-deploy` | GitHub Actions (WIF) | `roles/run.developer` on the project; `roles/iam.serviceAccountUser` on the runtime accounts |

IAM conditions (`B` = the bucket name):

- **(A)** `resource.name == "projects/_/buckets/B" || resource.name.startsWith("projects/_/buckets/B/objects/apparule/stg/")`
  (the first half allows listing, which the retention sweep needs)
- **(B)** `resource.name.startsWith("projects/_/buckets/B/objects/apparule/stg/tmp/")`
- **(C)** `resource.name.startsWith("projects/_/buckets/B/objects/apparule/stg/tmp/") || resource.name.startsWith("projects/_/buckets/B/objects/apparule/stg/compute/")`
- **(D)** `resource.name.startsWith("projects/_/buckets/B/objects/apparule/stg/compute/")`

Enable the APIs: Cloud Run, Cloud Scheduler, IAM Credentials, Firebase
Cloud Messaging, and Firebase App Hosting.

## 6. Configuration (Doppler `apparule/stg` → Cloud Run / App Hosting)

Names follow [system-design.md §10.3](system-design.md). Secrets are marked
🔒. Cloud Run sets `PORT` itself.

**Upload-ticket keys.** Generate once and keep the pair together:

```sh
cd api/common && go run ./cmd/ticketkey 2026-10
# UPLOAD_TICKET_PRIVATE_KEY=2026-10:…   → common only
# UPLOAD_TICKET_PUBLIC_KEYS=2026-10:…   → uploads only
```

| Variable | common | uploads | segmentation | commerce |
| --- | --- | --- | --- | --- |
| `DATABASE_URL` 🔒 | ✓ | | | |
| `FIREBASE_PROJECT_ID` | ✓ | | | |
| `UPLOAD_TICKET_PRIVATE_KEY` 🔒 | ✓ | | | |
| `UPLOAD_TICKET_PUBLIC_KEYS` | | ✓ | | |
| `UPLOADS_URL` (the uploads `run.app` URL plus `/api/v1/uploads`) | ✓ | | | |
| `SCHEDULER_AUDIENCE` (the common `run.app` URL) | ✓ | | | |
| `SCHEDULER_INVOKER_EMAIL` (`scheduler-invoker@sandbox-e306a.iam.gserviceaccount.com`) | ✓ | | | |
| `KAFKA_BROKERS`, `KAFKA_SSL_CA` | ✓ | ✓ | ✓ | ✓ |
| `KAFKA_USERNAME`, `KAFKA_PASSWORD` 🔒 | ✓ `apparule` | ✓ | ✓ | ✓ |
| `REDIS_HOST/PORT/USERNAME`, `REDIS_PASSWORD` 🔒, `REDIS_TLS=true`, `REDIS_DB`, `REDIS_KEY_PREFIX` | ✓ | | | |
| `STORAGE_DRIVER=gcs`, `STORAGE_BUCKET`, `STORAGE_PREFIX=apparule/stg` | ✓ | ✓ | ✓ | ✓ |
| `PAYSTACK_SECRET_KEY` 🔒 | ✓ (webhook signatures) | | | ✓ (API calls) |
| `PAYSTACK_PUBLIC_KEY` | ✓ (checkout) | | | |
| `FCM_PROJECT_ID` | | | | ✓ |
| `BREVO_API_KEY` 🔒, `BREVO_FROM_EMAIL`, `BREVO_FROM_NAME` | | | | ✓ |
| `CORS_ORIGINS` (the website origin) | ✓ | ✓ | | |
| `WAKE_COMMON_URL` (the common URL) | | ✓ | ✓ | ✓ |
| `WAKE_SEGMENTATION_URL`, `WAKE_COMMERCE_URL` | ✓ | | | |

The `WAKE_*` values are the services' own `https://…run.app` URLs, without a
path. Create the services first, then fill these in and redeploy.

Never set in cloud: `FIREBASE_AUTH_EMULATOR_HOST`, `STORAGE_ENDPOINT`, the
and the `STORAGE_*_KEY`s (those are for self-host).

**Paystack:** in the dashboard, set the webhook URL to
`https://apparule-api-common-805800737799.us-central1.run.app/webhooks/payments`, and use test keys until
the money flow has run end to end on the sandbox.

**Website (App Hosting, `web/`):**

| Variable | Available at | Value |
| --- | --- | --- |
| `NEXT_PUBLIC_TEST_MODE` | build | `1` until §9, then remove |
| `NEXT_PUBLIC_FIREBASE_API_KEY`, `_AUTH_DOMAIN`, `_PROJECT_ID` | build | from §2 step 3 |
| `API_ORIGIN` | runtime | the common URL (`https://…run.app`) |
| `UPLOADS_ORIGIN` | runtime | the uploads URL |

## 7. Cloud Run resources (cuesoft-iac stack)

Add these to the `cuesoft` stack (project `sandbox-e306a`, `us-central1`). The first image can be any tag from
Docker Hub, because every release replaces it by digest.

| Name | Kind | Account | Port | Instances | CPU / memory | CPU allocation | Ingress / auth |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `apparule-api-common` | service | `apparule-common` | 8080 | **0**–2 | 1 / 512 MiB | request-based | all · no IAM check (the app checks Firebase tokens; webhooks check signatures; the sweeps check the scheduler token) |
| `apparule-api-uploads` | service | `apparule-uploads` | 8082 | 0–5 | 1 / 1 GiB, concurrency 20, timeout 60 s | request-based | all · no IAM check (auth is the upload ticket) |
| `apparule-api-segmentation` | service | `apparule-segmentation` | 8081 | **0**–2 | 2 / 2 GiB, concurrency 2, startup probe ≥ 60 s | request-based | all · **authenticated only** (invoker: `apparule-common`) |
| `apparule-api-commerce` | service | `apparule-commerce` | 8083 | **0**–2 | 1 / 512 MiB | request-based | all · **authenticated only** (invoker: `apparule-common`) |

Every service has the URL `https://<service>-805800737799.us-central1.run.app`.
Cloud Scheduler POSTs `/internal/jobs/<name>` on `apparule-api-common` for
`captures` (`* * * * *`), `orders` (`7 * * * *`), `reconcile`
(`13 * * * *`) and `retention` (`17 3 * * *`), with an OIDC token from
`scheduler-invoker` whose audience is the common URL; the jobs are created
paused and resumed once this release is deployed. There is no load balancer:
the web proxies `/api/v1/*` to common.

In gcloud terms: `--min-instances 0` everywhere, with CPU allocated only
during requests. The processing services'
ingress is **all** rather than internal because common wakes
them over their `run.app` URLs; requiring authentication keeps them
private (the wake-ups carry an ID token).

**Idle.** While nobody uses the app nothing runs. Each wake keeps an
instance for up to ~15 minutes. Aiven (Postgres, Valkey, Kafka) is shared and stays up; the `captures` sweep wakes common for a short run every minute.

## 8. GitHub (release workflow)

On `cuesoftinc/apparule`:

1. **Environment `Sandbox`** with required reviewers, and these environment
   **variables**: `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_WORKLOAD_IDENTITY_PROVIDER`
   (`projects/<number>/locations/global/workloadIdentityPools/<pool>/providers/<provider>`),
   `GCP_DEPLOY_SERVICE_ACCOUNT` (the `apparule-deploy` email).
2. **Repository secrets**: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (push to
   `cuesoft/apparule-api-*`).
3. **Tag ruleset** restricting `v*` tag creation to owners.
4. The WIF provider trusts this repository, and `apparule-deploy` grants it
   `roles/iam.workloadIdentityUser`.

## 9. First release and switching the website over

1. Merge to `main`; confirm the site still works (TEST_MODE, §0).
2. Create the infrastructure (§2–§7) and fill Doppler (§6).
3. Tag a release: `git tag v0.2.0 && git push origin v0.2.0`. Approve the
   `Sandbox` deployment when GitHub asks.
4. The workflow fails unless every service's newest revision is Ready and
   common answers `/ready`. Check `apparule-api-common`'s logs for
   `migration applied` (first deploy only) and `listening`.
5. In App Hosting, set `API_ORIGIN`, `UPLOADS_ORIGIN` and the
   `NEXT_PUBLIC_FIREBASE_*` values, **then remove `NEXT_PUBLIC_TEST_MODE`**
   and roll out.
6. Smoke test on the site: sign in with Google, accept the terms, choose a
   measurement set, upload a front and a side photo, wait for results, save
   them. Follow the trail in the logs by `jsonPayload.step` and the session
   id: `capture.uploaded` → `wake` → `outbox` → `capture.ready` →
   `capture.measured`. Then, with a designer account, add a payout account
   (Paystack test bank), post, request it from another account, quote, pay
   with a Paystack test card, ship, confirm: `charge_settled` and
   `payout_released` appear in common's logs.
7. Leave the app alone for 20 minutes and check that every service shows
   0 instances. Then capture again: it should work, slower the first time.

## 10. Day-2

| Task | How |
| --- | --- |
| Roll back | Redeploy the previous image digest (it is in the earlier release run) with `gcloud run services update <name> --image docker.io/cuesoft/apparule-api-<svc>@sha256:…` |
| Rotate the ticket key | Generate a new pair with a new kid; **add** its public key to `UPLOAD_TICKET_PUBLIC_KEYS` (comma-separated) and deploy uploads; switch `UPLOAD_TICKET_PRIVATE_KEY` and deploy common; after 5 minutes, drop the old public key |
| Run migrations alone | `./jobs migrate` by hand (common also runs them on start); the HTTP sweeps exclude it |
| A capture stuck in "processing" | The `captures` sweep re-sends it after 60 s and fails it with `pipeline_busy` after 180 s; check segmentation's logs and the `wake` lines for `wake failed` |
| Kafka powered off (idle) | Expendit's reaper powers it back on; uploads answer 503 meanwhile and overdue captures are re-sent from Postgres. Nothing is lost from Postgres |
| A money outcome needs a human | `payments.outcome` rows of kind `mismatch`, `charge_rejected`, `payout_failed` or `refund_failed` are logged at error level (`money needs attention`) and kept in `payment_outcome` with `resolved_at` empty; resolve in Paystack, then set `resolved_at` |
| Resolve a dispute | A staff account calls `POST /api/v1/moderation/requests/{id}/resolve` with `delivered` or `refunded` |
| Delete a Firebase user | After the retention sweep purges or anonymizes an account, delete its Firebase user in the console (not automated yet) |

## 11. Not built yet

The Flutter app's remote repositories (waiting on `flutterfire configure`),
the two-view measurement benchmark that calibrates `mediapipe_2d_v2`
(capture-qc.md §3), SMPL (Phase 5), workspace customers for tailor shops
(and their consent, open question 7), Upstat events (D2), and OpenTelemetry
export.
