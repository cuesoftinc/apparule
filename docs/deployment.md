# Deployment — Cloud Contract

> Implements decision X-3 for the ratified system design (S-1…S-15,
> system-design.md §10). The step-by-step for an account owner is the
> [deploy runbook](deploy-runbook.md). Cloud deploys follow the proven cueprise/getpp
> patterns; provisioning goes through the **cuesoft-iac** Pulumi ecosystem —
> never ad-hoc gcloud. Self-hosting via `deploy/` (compose/helm/terraform)
> shares only images.

## 1. Topology

| Surface | Runs on | Provisioned by |
| --- | --- | --- |
| `api/common` (Go) | Cloud Run service + Cloud Run jobs (sweeps) | cuesoft-iac stack `apparule` |
| `api/uploads` (Node) | Cloud Run service | cuesoft-iac stack `apparule` |
| `api/segmentation` (Python) | Cloud Run service | cuesoft-iac stack `apparule` |
| `api/commerce` (Python) | Cloud Run service | cuesoft-iac stack `apparule` |
| `web` (Next.js) | **Firebase App Hosting** | App Hosting backend |
| Postgres, Redis | Aiven (GCP us-central1) | cuesoft-iac / Aiven console |
| Kafka | the CueLABS shared Aiven service (X-11); three lanes | owned by the fleet; Expendit keeps it awake |
| Object storage | default bucket in `sandbox-e306a`, prefix `apparule/<env>/` | cuesoft-iac |
| `mobile/flutter` | App/Play stores | out of band |

`api.apparule.cuesoft.io` is an external HTTPS load balancer with serverless
NEGs: `/api/v1/uploads` → `api/uploads`, everything else (including
`/webhooks/payments`) → `api/common`. `segmentation` and `commerce` have no
public ingress and accept only authenticated calls (the wake-ups carry a
Cloud Run ID token).

## 2. Provisioning (cuesoft-iac)

- **Pulumi, bun runtime**; state in `gs://cuesoft-iac-pulumi-state-bucket`;
  per-product stack (`Pulumi.<product>.yaml`).
- Cloud Run services instantiate `common/modules/gcp/cloud-run-service.ts`;
  the GitHub→GCP deploy identity uses **Workload Identity Federation**
  (`common/helpers/wif.ts`) — no service-account keys in GitHub.
- One service account per service, with Storage IAM per prefix (S-11):
  `uploads` creates objects in `tmp/` only; `segmentation` reads `tmp/` and
  writes `compute/`; `commerce` reads and writes `compute/`; `common` reads and
  writes everything and signs URLs (`roles/iam.serviceAccountTokenCreator` on
  itself). `media/` is readable by `allUsers` (published post images).
- Bucket lifecycle: delete `apparule/<env>/tmp/` and `compute/` objects after
  1 day.
- Postgres: an `apparule` database owned by a **non-superuser** role, so
  row-level security applies (superusers bypass it).
- Kafka: the `apparule` user with produce and consume on the three
  `cuelabs.*` lanes; consumer groups `apparule-common`,
  `apparule-segmentation`, `apparule-commerce`.
- Secrets flow from **Doppler** (`apparule/stg`) into Cloud Run env; the
  repo's `.env.example` files document every name, Doppler owns the values.

## 3. CI/CD (GitHub Actions, cueprise/getpp pattern)

| Workflow | Trigger | Does |
| --- | --- | --- |
| `build-and-test.yml` | PRs **and** push to `main` | per service: Go vet + tests (with a Postgres service for the RLS suite), uploads typecheck/lint/test/build, ruff + pytest for segmentation and commerce, web and mobile gates — **no deploy, no image push** (X-6) |
| `release.yml` | **tag `v*` created** | builds and pushes `cuesoft/apparule-api-{common,uploads,segmentation,commerce}` (tags: version, sha, `latest`), then in the protected `Sandbox` environment authenticates by WIF and points the Cloud Run services and sweep jobs at the new **digests**; fails unless every new revision is Ready and `common` answers `/ready` |

**Gating (X-6):** `stg` (sandbox) is the only environment and is treated as
production. Two independent gates: a GitHub **tag ruleset** restricts `v*`
tags to owner-level access, and the deploy job runs in the protected
**`Sandbox`** environment with required reviewers. A merged PR never reaches
the sandbox on its own. The web keeps App Hosting rollouts.

Two hard-won rules inherited from cueprise, non-negotiable:

1. **Deploy by digest, never by tag** — Cloud Run pulls Docker Hub images
   through the `mirror.gcr.io` cache, which has served stale manifests for
   tags.
2. **WIF only** (`google-github-actions/auth`) — no JSON keys.

## 4. Runtime contract (Cloud Run) **[Decided]**

| Service | CPU / mem | Concurrency | Instances | CPU allocation | Ingress |
| --- | --- | --- | --- | --- | --- |
| api/common | 1 vCPU / 512 MiB | 80 | 0–2 | always | all (via the LB) |
| api/uploads | 1 vCPU / 512 MiB | 20 | 0–5 | request | all (via the LB) |
| api/segmentation | 2 vCPU / 2 GiB | 2 | 0–2 | always | all, authenticated only (run.invoker) |
| api/commerce | 1 vCPU / 512 MiB | 20 | 0–2 | always | all, authenticated only (run.invoker) |
| sweeps | the common image, `./jobs <name>` | — | Cloud Scheduler | — | — |

**Scale to zero** (S-9 as amended, shared-messaging.md): every service runs
at min 0. Consumers keep CPU for the life of an instance; whoever publishes
for a sleeping service wakes it with `GET /health` — `uploads` → `common`,
`common`'s outbox → `segmentation` or `commerce`, the processing services →
`common`. Base URLs come from `WAKE_<TARGET>_URL`. The sweeps wake whatever
has work pending.

| Sweep | Schedule |
| --- | --- |
| `captures` | every minute |
| `orders` | hourly |
| `reconcile` | hourly |
| `retention` | daily |

- Rollback: redeploy the previous image digest (recorded in the release run);
  `gcloud run services update-traffic` to the prior revision is the fast
  path. A broken release is rolled back before any forward fix.
- Web env: `NEXT_PUBLIC_FIREBASE_*` values flow Doppler → `apphosting.yaml`;
  `API_ORIGIN` and `UPLOADS_ORIGIN` are server-side and read per request.

## 5. Self-host

`make up` runs the whole stack on compose (system-design.md §10.2):
Postgres 18 with the non-superuser app role, Kafka 4 (KRaft) with the three
lanes, Redis, SeaweedFS for S3, the Firebase auth emulator, the four
services, a sweep loop, and the web. The Helm chart (`deploy/helm`) deploys
the same images with per-service secrets, the sweeps as CronJobs, and an
optional API ingress host; Terraform installs the chart. Without Paystack
keys, `commerce` runs notify-only.
