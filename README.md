# Apparule

Fashion body-measurement and social-commerce platform — capture body
measurements from a phone, keep them in a private vault, and commission
outfits from designers with a frozen copy of your measurements.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![build-and-test](https://github.com/cuesoftinc/apparule/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/cuesoftinc/apparule/actions/workflows/build-and-test.yml)

## Overview

Apparule is a monorepo containing the clients, backend services, deployment
configuration, and documentation for the platform. A Go service owns the product
API and all data, a Node gateway takes uploads, one Python service turns two
phone photos into body measurements and another makes every payment decision,
and a Next.js frontend serves the marketing site and user dashboard. The
services talk over the CueLABS shared Kafka. For the components and how they
fit together, see [docs/overview.md](docs/overview.md) and the
[system design](docs/system-design.md).

## Architecture

```mermaid
flowchart LR
    subgraph clients
        WEB[web + dashboard<br/>Next.js — App Hosting]
        MOB[Flutter mobile]
    end
    FB[Firebase Auth<br/>Google only]
    subgraph server["GCP Cloud Run (scale to zero)"]
        AC[api/common — Go<br/>CRUD]
        UP[api/uploads — Node<br/>upload gateway]
        SG[api/segmentation — Python<br/>pose QC · measurements]
        CM[api/commerce — Python<br/>payments · notifications]
    end
    subgraph data
        PG[(Aiven Postgres)]
        CS[(Cloud Storage)]
        RD[(Aiven Redis)]
        K[[CueLABS shared Kafka]]
    end
    WEB --> FB
    MOB --> FB
    WEB --> AC
    MOB --> AC
    WEB --> UP
    MOB --> UP
    AC --> PG
    AC --> RD
    UP --> CS
    UP --> K
    AC <--> K
    K <--> SG
    K <--> CM
```

### Tech stack

| Layer          | Technology                                          |
| -------------- | --------------------------------------------------- |
| Backend API    | Go 1.26, Postgres with row-level security (`api/common`) |
| Upload gateway | Node 24, NestJS, sharp (`api/uploads`)              |
| Measurement    | Python 3.12, MediaPipe, OpenCV (`api/segmentation`) |
| Payments       | Python 3.12, Paystack, FCM, Brevo (`api/commerce`)  |
| Messaging      | Kafka (the CueLABS shared Aiven service)            |
| Web            | Next.js, React, TypeScript                          |
| Mobile         | Flutter (primary), native Android/iOS               |
| Auth & data    | Firebase Google-only auth; Aiven Postgres (system of record) & Cloud Storage; shared Aiven Redis |
| Infrastructure | Docker, Helm, Terraform, GCP Cloud Run              |

## Repository structure

```
api/
  common/        Go — the product API, the only Postgres client; Kafka contract
  uploads/       Node — ticketed upload gateway
  segmentation/  Python — pose QC and body measurements
  commerce/      Python — payment decisions, push and email
web/           Next.js marketing site + user dashboard
mobile/
  flutter/     Flutter app (primary mobile client)
  android/     Native Android (Kotlin)
  ios/         Native iOS (Swift)
deploy/
  docker/      Container/compose configuration
  helm/        Helm chart (deploys all services to Kubernetes)
  terraform/   Infrastructure as code
docs/          Project documentation
scripts/       Developer and CI helper scripts
```

Additional services follow the same convention: `api/common` is the shared Go
backend, and every other service lives under `api/<service-name>` named by its
function (never by its language).

## Getting started

### Prerequisites

- [Docker](https://www.docker.com/) & Docker Compose (recommended path)
- For native development: [Go](https://go.dev/) 1.26, [Node.js](https://nodejs.org/) 24,
  Python 3.12, and [Flutter](https://flutter.dev/)

### Quick start

```bash
cp .env.example .env
make up      # build + start the stack: web (:3000), common (:8080), segmentation (:8081),
             # uploads (:8082), commerce (:8083), plus Postgres, Kafka, Redis, S3, Firebase emulator
make logs    # follow logs
make down    # stop
```

Configuration is provided at runtime via environment variables (names in
[system-design.md §10.3](docs/system-design.md)); the compose defaults need
nothing but the local-only ticket key pair already in `.env.example`. See
[docs/setup.md](docs/setup.md) for details; `make help` lists all targets.
Never commit credentials or bake them into an image.

## Documentation
- [Hosted docs](https://cuesoft.gitbook.io/apparule) — the full documentation site (auto-synced from `docs/`)

- [Project overview](docs/overview.md) — architecture and components
- [System design](docs/system-design.md) — services, transports, data ownership, flows
- [Local setup](docs/setup.md) — development environment and per-service run commands

## Contributing

Contributions are welcome. Please read the [Contributing guide](CONTRIBUTING.md)
and our [Code of Conduct](CODE_OF_CONDUCT.md) before opening a PR.

## Security

Please report vulnerabilities privately — see our [Security policy](SECURITY.md).

## License

See [LICENSE](LICENSE).
