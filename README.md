# Apparule

Fashion body-measurement platform — capture body measurements from a phone and
turn them into sizing data for a better-fitting shopping experience.

## Overview

Apparule is a monorepo containing the clients, backend services, deployment
configuration, and documentation for the platform. For a deeper description of
the components and how they fit together, see [docs/overview.md](docs/overview.md).

```
client                                   server
──────                                   ──────
web + dashboard (Next.js) ─┐             common api (Go)      ── GCP Cloud Run
                           ├─ Firebase /  measure api (Python) ── GCP Cloud Run
flutter mobile ────────────┘  Google auth
                                         data: Firebase Firestore & Storage,
                                               Aiven Postgres & Valkey (Redis)
```

## Repository structure

```
api/
  common/      Go service — authentication and core API
  measure/     Python service — MediaPipe pose-based body measurement
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
function.

## Getting started

See [docs/setup.md](docs/setup.md) for prerequisites and per-service run
commands. Common tasks are wired into the [Makefile](Makefile).

Configuration is provided at runtime via environment variables — for example
`FIREBASE_CONFIG_PATH`, the path to the Firebase service-account JSON used by
`api/common`. Never commit credentials or bake them into an image.

## Contributing

Contributions are welcome. Please read the [Contributing guide](CONTRIBUTING.md)
and our [Code of Conduct](CODE_OF_CONDUCT.md) before opening a PR.

## Security

Please report vulnerabilities privately — see our [Security policy](SECURITY.md).

## License

See [LICENSE](LICENSE).
