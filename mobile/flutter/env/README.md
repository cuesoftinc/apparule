# Env files (gitignored)

Secrets reach the app via `--dart-define-from-file=env/<flavor>.json`,
generated from your own secrets (mobile-implementation.md §2, X-5). Two
flavors (M-7 in decisions.md): `env/dev.json` configures the `dev` flavor
(fake repositories, local development), and `env/prod.json` configures the
`prod` flavor (the deployed environment). Generate each by exporting the
matching secrets set from your secrets manager as a flat JSON object of
`KEY: value` pairs. The JSON files are never committed, only this README is
tracked.

The first consumer is `API_URL` (`apiAuthRepositoryOverride()`): the origin
that serves `/api/v1`, with no path and no trailing slash. It must be the
same host as the API's `GOOGLE_REDIRECT_URI`, so the sign-in state cookie set
when the browser tab opens reaches the Google callback.
