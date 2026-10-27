# Apparule uploads (`api/uploads`)

The thin, stateless upload gateway (NestJS, port 8082; docs/system-design.md
§4, §6.1). Its one public route is `POST /api/v1/uploads`, and it accepts
nothing without an upload ticket from `api/common`:

1. Verify the `Upload-Ticket` (Ed25519, `common`'s public key, no call back;
   format in [api/common/contract/upload-ticket.md](../common/contract/upload-ticket.md)).
2. Check the declared size, then read exactly the parts the ticket allows:
   `image_front` / `image_side` for a capture (both, or the one pose a retake
   ticket names), up to ten `images` for post media, one for a thread
   attachment.
3. Check each image's magic bytes (JPEG, PNG, WebP, HEIC) and that it decodes,
   then strip EXIF and GPS and re-encode to JPEG at ≤ 2048 px.
4. Write each to `apparule/<env>/tmp/<kind>/<target>/<ticket>/<pose|n>.jpg`
   and publish `apparule.capture.uploaded` or `apparule.media.uploaded` on the
   shared bus's `cuelabs.uploads` lane, by pointer.
5. Answer `202`. Errors use the ecosystem envelope and name the failing
   `pose`; while Kafka or storage is away the answer is `503` with
   `Retry-After`.

No database, no Redis, no user tokens. Limits and quotas are enforced in
`common` before the ticket exists.

## Layout

```
src/main.ts            bootstrap: CORS (POST + Upload-Ticket only), $PORT
src/config/            typed env config (fails fast)
src/ticket/            ticket verification
src/upload/            the route, multipart parsing, checks and cleaning
src/filetype/          magic-byte detection
src/storage/           Cloud Storage (ADC) or MinIO
src/kafka/             producer (claim-check), event names, wake-up of common
src/contract/          JSON Schema validation (api/common/contract)
src/health/            /health and /ready
```

## Run

From the repo root (recommended): `make up`. Natively:

```bash
cp .env.example .env   # set UPLOAD_TICKET_PUBLIC_KEYS (go run ./cmd/ticketkey in api/common)
npm ci && npm run dev
```

## Test

```bash
npm test        # ticket, file type, and the route end to end with fakes
npm run lint && npm run typecheck
```
