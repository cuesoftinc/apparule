# Env files (gitignored)

Secrets reach the app via `--dart-define-from-file=env/<flavor>.json`,
generated from the `apparule` Doppler project (mobile-implementation.md
§2, X-5). Two flavors (org environment ruling, user directive
2026-07-22): `env/dev.json` from the Doppler `dev` config, and
`env/prod.json` from the Doppler `stg` config — CueLABS production runs
on the sandbox account, so the Doppler config NAME stays `stg` while the
environment it feeds is production. The JSON files are never committed —
only this README is tracked.

The first consumer is the auth wave's `GOOGLE_SERVER_CLIENT_ID`
(prod flavor, `firebaseAuthRepositoryOverride()`); the API base URL
joins with the API wave.
