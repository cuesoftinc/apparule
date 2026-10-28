# Deployment — Cloud Contract

> Implements decision X-3 for the ratified system design (S-1…S-15,
> system-design.md §10). The step-by-step for an account owner is the
> [deploy runbook](deploy-runbook.md). Cloud deploys follow proven
> patterns; provisioning goes through the **IaC** Pulumi stack —
> never ad-hoc gcloud. Self-hosting via `deploy/` (compose/helm/terraform)
> shares only images.

## 1. Topology

| Surface | Runs on | Provisioned by |
| --- | --- | --- |
| `api/common` (Go) | Cloud Run service `apparule-api-common` (the sweeps are its `/internal/jobs/<name>` routes) | IaC stack, project `sandbox-e306a`, `us-central1` |
| `api/uploads` (Node) | Cloud Run service `apparule-api-uploads` | IaC stack |
| `api/segmentation` (Python) | Cloud Run service `apparule-api-segmentation` | IaC stack |
| `api/commerce` (Python) | Cloud Run service `apparule-api-commerce` | IaC stack |
| `web` (Next.js) | **Firebase App Hosting** | App Hosting backend |
| Postgres, Valkey | the shared Aiven `sandbox-db` and `sandbox-cache` (database `apparule`, user `cuesoft`; keys `apparule:*`) | IaC |
| Kafka | the CueLABS shared Aiven service (X-11); three lanes; SASL user `apparule` with topic ACLs | IaC; Expendit keeps it awake |
| Object storage | `sandbox-e306a.firebasestorage.app`, prefix `apparule/stg/`; media by signed URL | IaC |
| `mobile/flutter` | App/Play stores | out of band |

Each service has its `run.app` URL, `https://<service>-805800737799.us-central1.run.app`.
The web proxies `/api/v1/*` to `api/common` (uploads to `api/uploads`); there
is no load balancer. Paystack posts to `api/common`'s `/webhooks/payments`.
`segmentation` and `commerce` accept only authenticated calls (the wake-ups
carry a Cloud Run ID token).

## 2. Provisioning (IaC)

- **Pulumi, bun runtime**; state in a GCS state bucket;
  per-product stack (`Pulumi.<product>.yaml`).
- Cloud Run services instantiate the shared Cloud Run service
  module; the GitHub→GCP deploy identity uses **Workload Identity
  Federation** — no service-account keys in GitHub.
- One service account per service (`apparule-common`, `apparule-uploads`,
  `apparule-segmentation`, `apparule-commerce`), each limited to its
  prefixes of the shared bucket (S-11): `uploads` creates objects in `tmp/`
  only; `segmentation` reads `tmp/` and `compute/` and writes `compute/`;
  `commerce` reads and writes `compute/`; `common` reads and writes
  everything under `apparule/stg/` and signs URLs
  (`roles/iam.serviceAccountTokenCreator` on itself). No object is public:
  media is served by signed URLs.
- Bucket lifecycle: delete `apparule/stg/tmp/` and `compute/` objects after
  1 day.
- Postgres: the `apparule` database and user on the shared `sandbox-db`,
  a **non-superuser** role, so row-level security applies (superusers bypass
  it).
- Valkey: the `apparule` user on the shared `sandbox-cache`, allowed keys
  `apparule:*` only (`REDIS_KEY_PREFIX`, default `apparule`).
- Kafka: the `apparule` SASL user with topic ACLs (read and write) on the
  three `cuelabs.*` lanes; consumer groups `apparule-common`,
  `apparule-segmentation`, `apparule-commerce`. If the free plan refuses
  SASL, client certificates take its place.
- Cloud Scheduler: `apparule-captures`, `apparule-orders`,
  `apparule-reconcile`, `apparule-retention` POST
  `/internal/jobs/<name>` on `apparule-api-common` with an OIDC token
  (audience the service URL, invoker `scheduler-invoker@sandbox-e306a.iam.gserviceaccount.com`),
  created paused until the handlers are deployed.
- GitHub: the `Sandbox` environment of `cuesoftinc/apparule` gets the
  variables `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_WORKLOAD_IDENTITY_PROVIDER`
  and `GCP_DEPLOY_SERVICE_ACCOUNT`.
- Secrets flow from **Doppler** (project `apparule`, config `stg`) into Cloud
  Run env; the repo's `.env.example` files document every name, Doppler owns
  the values.

## 3. CI/CD (GitHub Actions)

| Workflow | Trigger | Does |
| --- | --- | --- |
| `build-and-test.yml` | PRs **and** push to `main` | per service: Go vet + tests (with a Postgres service for the RLS suite), uploads typecheck/lint/test/build, ruff + pytest for segmentation and commerce, web and mobile gates — **no deploy, no image push** (X-6) |
| `release.yml` | **push to `main` touching `api/**`** | builds and pushes `cuesoft/apparule-api-{common,uploads,segmentation,commerce}` (tags: sha, `latest`), then in the `Sandbox` environment authenticates by WIF and points the Cloud Run services at the new **digests**; fails unless every new revision is Ready and `common` answers `/ready` |

**Gating (X-6, revised 2026-10-27):** `stg` (sandbox) is the only
environment. A merge to `main` that touches `api/**` deploys the API services
to the sandbox; review and merge rights on `main` are the gate. The deploy job
runs in the `Sandbox` environment, which holds the WIF variables. No version
tags: images carry the commit sha and `latest`. The web keeps App Hosting rollouts.

Two hard-won rules, non-negotiable:

1. **Deploy by digest, never by tag** — Cloud Run pulls Docker Hub images
   through the `mirror.gcr.io` cache, which has served stale manifests for
   tags.
2. **WIF only** (`google-github-actions/auth`) — no JSON keys.

## 4. Runtime contract (Cloud Run) **[Decided]**

| Service | CPU / mem | Concurrency | Instances | CPU allocation | Ingress |
| --- | --- | --- | --- | --- | --- |
| api/common | 1 vCPU / 512 MiB | 80 | 0–2 | request | all, no IAM check (the app checks session tokens, webhook signatures and the scheduler token) |
| api/uploads | 1 vCPU / 1 GiB | 20 | 0–5 | request | all, no IAM check (auth is the upload ticket) |
| api/segmentation | 2 vCPU / 2 GiB | 2 | 0–2 | request | all, authenticated only (invoker `apparule-common`) |
| api/commerce | 1 vCPU / 512 MiB | 80 | 0–2 | request | all, authenticated only (invoker `apparule-common`) |

**Scale to zero** (S-9 as amended, shared-messaging.md): every service runs
at min 0, with no always-on instance, worker pool or Cloud Run job. Whoever
publishes for a sleeping service wakes it with `GET /health`: `uploads` →
`common`, `common`'s outbox → `segmentation` or `commerce`, the processing
services → `common`. Base URLs come from `WAKE_<TARGET>_URL`. The sweeps wake
whatever has work pending.

Cloud Scheduler POSTs `/internal/jobs/<name>` on `apparule-api-common` with
an OIDC token. The handler checks the audience (`SCHEDULER_AUDIENCE`, the
service URL) and the invoker (`SCHEDULER_INVOKER_EMAIL`) and answers 401, 403
or, when either is unset, 503.

| Job | Schedule |
| --- | --- |
| `captures` | every minute |
| `orders` | hourly |
| `reconcile` | hourly |
| `retention` | daily |

- Rollback: redeploy the previous image digest (recorded in the release run);
  `gcloud run services update-traffic` to the prior revision is the fast
  path. A broken release is rolled back before any forward fix.
- Web env: `API_URL` and `UPLOADS_URL` are server-side and read per request.

## 5. Self-host

`make up` runs the whole stack on compose (system-design.md §10.2):
Postgres 18 with the non-superuser app role, Kafka 4 (KRaft) with the three
lanes, Redis, SeaweedFS for S3, the four
services, a sweep loop, and the web. The Helm chart (`deploy/helm`) deploys
the same images with per-service secrets, the sweeps as CronJobs, and an
optional API ingress host; Terraform installs the chart. Without Paystack
keys, `commerce` runs notify-only.
