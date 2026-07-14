# Apparule Web (`web`)

Next.js 16 (App Router, TypeScript) front-end for Apparule. Currently a
scaffold: typed env plumbing (`src/config/env.ts`) and an API client for
`api/common` (`src/lib/api.ts`) are in place; product UI lands with the PRD
work.

## Run

From the repo root (recommended): `make up` → http://localhost:3000

Dev server:

```bash
npm install
npm run dev
```

`NEXT_PUBLIC_*` values are inlined at build time — set them in the root `.env`
(see `.env.example`).
