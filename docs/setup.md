# Local Setup

## Prerequisites

- Go (see `api/common/go.mod`)
- Python 3.11+ (for `api/measure`)
- Node.js 20+ (for `web`)
- Flutter (for `mobile/flutter`)

## Configuration

Never commit secrets. Provide configuration via environment variables:

| Variable | Used by | Description |
|----------|---------|-------------|
| `FIREBASE_CONFIG_PATH` | `api/common` | Path to the Firebase service-account JSON. Injected at runtime; never baked into an image. |

## Running services

```bash
# Go API
cd api/common && go run .

# Python measurement service
cd api/measure && pip install -r requirements.txt && python pose_detector.py

# Web
cd web && npm install && npm run dev

# Mobile
cd mobile/flutter && flutter pub get && flutter run
```

Common tasks are also wired into the root [Makefile](../Makefile).
