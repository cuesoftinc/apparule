# Env files (gitignored)

Secrets reach the app via `--dart-define-from-file=env/<flavor>.json`,
generated from the `apparule` Doppler project's `dev`/`stg`/`prd` configs
(mobile-implementation.md §2, X-5). The JSON files are never committed —
only this README is tracked.

No env values are consumed yet; the first consumers arrive with the
auth/API waves (API base URL, Google serverClientId).
