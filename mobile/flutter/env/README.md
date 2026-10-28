# Env files (gitignored)

Secrets reach the app via `--dart-define-from-file=env/<flavor>.json`,
generated from the `apparule` Doppler project (mobile-implementation.md
§2, X-5). Two flavors (org environment ruling, user directive
2026-07-22): `env/dev.json` from the Doppler `dev` config, and
`env/prod.json` from the Doppler `stg` config — CueLABS production runs
on the sandbox account, so the Doppler config NAME stays `stg` while the
environment it feeds is production. The JSON files are never committed —
only this README is tracked.

The first consumer is `API_URL` (`apiAuthRepositoryOverride()`): the origin
that serves `/api/v1`, with no path and no trailing slash. It must be the
same host as the API's `GOOGLE_REDIRECT_URI`, so the sign-in state cookie set
when the browser tab opens reaches the Google callback.
